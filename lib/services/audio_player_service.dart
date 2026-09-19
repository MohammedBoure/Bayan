import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import '../models/reading_passage_model.dart';

enum AudioPlaybackState {
  stopped,
  playing,
  paused,
}

/// Service providing native offline audio playback for Windows (via winmm.dll MCI)
/// with graceful fallback for other platforms and automated tests.
class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService instance = AudioPlayerService._internal();
  AudioPlayerService._internal();

  static const String _alias = 'bustan_audio_player';

  DynamicLibrary? _winmm;
  int Function(Pointer<Utf16>, Pointer<Utf16>, int, int)? _mciSendString;

  AudioPlaybackState _state = AudioPlaybackState.stopped;
  ReadingAudioTrack? _currentTrack;
  int _durationMs = 0;
  int _positionMs = 0;
  Timer? _ticker;

  AudioPlaybackState get state => _state;
  ReadingAudioTrack? get currentTrack => _currentTrack;
  int get durationMs => _durationMs;
  int get positionMs => _positionMs;
  bool get isPlaying => _state == AudioPlaybackState.playing;
  bool get isPaused => _state == AudioPlaybackState.paused;
  bool get isStopped => _state == AudioPlaybackState.stopped;

  void _initNative() {
    if (!Platform.isWindows || _mciSendString != null) return;
    try {
      _winmm = DynamicLibrary.open('winmm.dll');
      _mciSendString = _winmm!.lookupFunction<
          Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32, IntPtr),
          int Function(Pointer<Utf16>, Pointer<Utf16>, int, int)>('mciSendStringW');
    } catch (e) {
      debugPrint('AudioPlayerService: Error loading winmm.dll: $e');
    }
  }

  int _mci(String command, [Pointer<Utf16>? buffer, int bufferLen = 0]) {
    _initNative();
    if (_mciSendString == null) return -1;
    final cmd = command.toNativeUtf16();
    try {
      return _mciSendString!(cmd, buffer ?? nullptr, bufferLen, 0);
    } catch (e) {
      debugPrint('AudioPlayerService: MCI command error "$command": $e');
      return -1;
    } finally {
      calloc.free(cmd);
    }
  }

  Future<String?> _resolveAssetPath(String assetPath) async {
    try {
      // 1. Direct path from project root (development / debug)
      final devFile = File(assetPath);
      if (await devFile.exists()) {
        return devFile.absolute.path;
      }

      // 2. Relative to executable (Windows release portable build)
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final releaseFile = File(p.join(exeDir, 'data', 'flutter_assets', assetPath));
      if (await releaseFile.exists()) {
        return releaseFile.absolute.path;
      }

      // 3. Fallback: extract from rootBundle into system temp
      final tempDir = Directory.systemTemp;
      final safeName = assetPath.replaceAll('/', '_').replaceAll('\\', '_');
      final tempFile = File(p.join(tempDir.path, safeName));
      if (!await tempFile.exists()) {
        final data = await rootBundle.load(assetPath);
        await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      return tempFile.path;
    } catch (e) {
      debugPrint('AudioPlayerService: Could not resolve asset path $assetPath: $e');
      return null;
    }
  }

  /// Automatically inspects and rectifies PCM WAV byteRate if corrupted in header
  void _ensureValidWavHeader(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;
      final readRaf = file.openSync(mode: FileMode.read);
      final header = readRaf.readSync(44);
      readRaf.closeSync();

      if (header.length >= 36) {
        final format = header[20] | (header[21] << 8);
        final channels = header[22] | (header[23] << 8);
        final sampleRate = header[24] | (header[25] << 8) | (header[26] << 16) | (header[27] << 24);
        final byteRate = header[28] | (header[29] << 8) | (header[30] << 16) | (header[31] << 24);
        final bits = header[34] | (header[35] << 8);

        if (format == 1 && channels > 0 && sampleRate > 0 && bits > 0) {
          final expectedByteRate = sampleRate * channels * (bits ~/ 8);
          if (byteRate != expectedByteRate) {
            final writeRaf = file.openSync(mode: FileMode.writeOnlyAppend);
            writeRaf.setPositionSync(28);
            final brBytes = Uint8List(4)
              ..buffer.asByteData().setInt32(0, expectedByteRate, Endian.little);
            writeRaf.writeFromSync(brBytes);
            writeRaf.closeSync();
          }
        }
      }
    } catch (e) {
      debugPrint('AudioPlayerService: Error verifying WAV header: $e');
    }
  }

  /// Returns the duration of an audio track in milliseconds
  Future<int> getTrackDuration(ReadingAudioTrack track) async {
    if (_currentTrack?.assetPath == track.assetPath && _durationMs > 0) {
      return _durationMs;
    }
    final resolvedPath = await _resolveAssetPath(track.assetPath);
    if (resolvedPath != null) {
      try {
        final file = File(resolvedPath);
        if (await file.exists()) {
          final bytes = await file.openRead(0, 44).expand((chunk) => chunk).toList();
          if (bytes.length >= 36) {
            final channels = bytes[22] | (bytes[23] << 8);
            final sampleRate = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
            final bits = bytes[34] | (bytes[35] << 8);
            final byteRate = sampleRate * channels * (bits ~/ 8);
            final fileSize = await file.length();
            final dataLength = fileSize - 44;
            if (byteRate > 0) {
              return ((dataLength / byteRate) * 1000).round();
            }
          }
        }
      } catch (_) {}
    }
    return 60000;
  }

  /// Play a specific reading audio track
  Future<void> playTrack(ReadingAudioTrack track) async {
    if (_currentTrack?.assetPath == track.assetPath && _state == AudioPlaybackState.paused) {
      await resume();
      return;
    }

    await stop();

    _currentTrack = track;
    final resolvedPath = await _resolveAssetPath(track.assetPath);

    if (resolvedPath == null || !Platform.isWindows) {
      // Non-windows or failed to resolve: simulate state for mock/tests
      _state = AudioPlaybackState.playing;
      _durationMs = await getTrackDuration(track);
      _startTicker();
      notifyListeners();
      return;
    }

    _ensureValidWavHeader(resolvedPath);

    _mci('close $_alias');
    final openResult = _mci('open "$resolvedPath" type waveaudio alias $_alias');
    if (openResult != 0) {
      debugPrint('AudioPlayerService: Failed to open $resolvedPath, code: $openResult');
      return;
    }

    _mci('set $_alias time format milliseconds');

    final buffer = calloc<Uint16>(256).cast<Utf16>();
    _mci('status $_alias length', buffer, 256);
    final mciLen = int.tryParse(buffer.toDartString()) ?? 0;
    calloc.free(buffer);

    final calculatedDuration = await getTrackDuration(track);
    _durationMs = (mciLen > 0) ? mciLen : calculatedDuration;

    _mci('play $_alias from 0');
    _state = AudioPlaybackState.playing;
    _positionMs = 0;
    _startTicker();
    notifyListeners();
  }

  /// Pause current playback
  Future<void> pause() async {
    if (_state != AudioPlaybackState.playing) return;

    if (Platform.isWindows && _mciSendString != null) {
      _mci('pause $_alias');
    }
    _state = AudioPlaybackState.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  /// Resume playback from paused state
  Future<void> resume() async {
    if (_state != AudioPlaybackState.paused) return;

    if (Platform.isWindows && _mciSendString != null) {
      _mci('resume $_alias');
    }
    _state = AudioPlaybackState.playing;
    _startTicker();
    notifyListeners();
  }

  /// Stop current playback and reset position
  Future<void> stop() async {
    _ticker?.cancel();
    if (Platform.isWindows && _mciSendString != null) {
      _mci('stop $_alias');
      _mci('close $_alias');
    }
    _state = AudioPlaybackState.stopped;
    _positionMs = 0;
    notifyListeners();
  }

  /// Seek to a specific timestamp in milliseconds
  Future<void> seekTo(int ms) async {
    if (_state == AudioPlaybackState.stopped) return;

    _positionMs = ms.clamp(0, _durationMs);
    if (Platform.isWindows && _mciSendString != null) {
      if (_state == AudioPlaybackState.playing) {
        _mci('play $_alias from $_positionMs');
      } else {
        _mci('seek $_alias to $_positionMs');
      }
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!Platform.isWindows || _mciSendString == null) {
        if (_state == AudioPlaybackState.playing) {
          _positionMs += 300;
          if (_positionMs >= _durationMs) {
            stop();
          } else {
            notifyListeners();
          }
        }
        return;
      }

      final buffer = calloc<Uint16>(256).cast<Utf16>();
      _mci('status $_alias mode', buffer, 256);
      final mode = buffer.toDartString().toLowerCase();

      if (mode.contains('stopped') || mode.isEmpty) {
        calloc.free(buffer);
        stop();
        return;
      }

      _mci('status $_alias position', buffer, 256);
      final currentPos = int.tryParse(buffer.toDartString());
      calloc.free(buffer);

      if (currentPos != null) {
        _positionMs = currentPos;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
