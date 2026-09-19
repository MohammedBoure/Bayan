import 'package:flutter/material.dart';
import '../models/reading_passage_model.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

/// Classroom Audio Player widget for listening to text readings.
/// Specifically tailored for teachers using Data Show projectors or interactive screens.
class AudioPlayerWidget extends StatefulWidget {
  final List<ReadingAudioTrack> tracks;
  final ValueChanged<List<int>>? onTrackChanged;
  final VoidCallback? onClose;

  const AudioPlayerWidget({
    super.key,
    required this.tracks,
    this.onTrackChanged,
    this.onClose,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayerService _player = AudioPlayerService.instance;
  late int _selectedTrackIndex;
  int _knownDurationMs = 0;

  @override
  void initState() {
    super.initState();
    _selectedTrackIndex = 0;
    _player.addListener(_onPlayerStateChanged);
    _loadDuration();
  }

  Future<void> _loadDuration() async {
    if (widget.tracks.isNotEmpty && mounted) {
      final d = await _player.getTrackDuration(widget.tracks[_selectedTrackIndex]);
      if (mounted) {
        setState(() {
          _knownDurationMs = d;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(int ms) {
    final totalSec = (ms / 1000).floor();
    final minutes = (totalSec / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSec % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _selectTrack(int index) {
    if (_selectedTrackIndex == index && _player.isPlaying) return;
    setState(() {
      _selectedTrackIndex = index;
    });
    _loadDuration();
    final track = widget.tracks[index];
    widget.onTrackChanged?.call(track.paragraphIndices);
  }

  void _togglePlayPause() {
    final track = widget.tracks[_selectedTrackIndex];
    if (_player.isPlaying && _player.currentTrack?.assetPath == track.assetPath) {
      _player.pause();
    } else if (_player.isPaused && _player.currentTrack?.assetPath == track.assetPath) {
      _player.resume();
    } else {
      _player.playTrack(track);
      widget.onTrackChanged?.call(track.paragraphIndices);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tracks.isEmpty) return const SizedBox.shrink();

    final currentTrack = widget.tracks[_selectedTrackIndex];
    final isThisTrackPlaying = _player.isPlaying && _player.currentTrack?.assetPath == currentTrack.assetPath;
    final isThisTrackPaused = _player.isPaused && _player.currentTrack?.assetPath == currentTrack.assetPath;
    final isCurrentActive = isThisTrackPlaying || isThisTrackPaused;

    final duration = (isCurrentActive && _player.durationMs > 0)
        ? _player.durationMs
        : (_knownDurationMs > 0 ? _knownDurationMs : 1);
    final position = isCurrentActive ? _player.positionMs.clamp(0, duration) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // soft green tint
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + Title + Track Selector + Close Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.record_voice_over_rounded, color: AppTheme.successGreen, size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'الاستماع الصوتي للنص (قراءة نموذجية معبرة):',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              // Track tabs if multiple
              if (widget.tracks.length > 1)
                Wrap(
                  spacing: 6,
                  children: List.generate(widget.tracks.length, (i) {
                    final isSelected = _selectedTrackIndex == i;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        widget.tracks[i].title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.primaryDark,
                        ),
                      ),
                      selectedColor: AppTheme.successGreen,
                      backgroundColor: Colors.white,
                      onSelected: (_) => _selectTrack(i),
                    );
                  }),
                ),
              if (widget.onClose != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onClose,
                  tooltip: 'إخفاء شريط الصوت',
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.textMuted),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Player bar: Play/Pause, Stop, Progress bar, Timestamps
          Row(
            children: [
              // Play / Pause Button
              ElevatedButton.icon(
                onPressed: _togglePlayPause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isThisTrackPlaying ? AppTheme.accentOrange : AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  isThisTrackPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26,
                ),
                label: Text(
                  isThisTrackPlaying
                      ? 'إيقاف مؤقت'
                      : (isThisTrackPaused ? 'متابعة الاستماع' : 'استمع للفقرة'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),

              // Stop Button
              if (isCurrentActive)
                IconButton.filledTonal(
                  onPressed: () {
                    _player.stop();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: AppTheme.textDark,
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 24),
                  tooltip: 'إيقاف نهائي',
                ),

              const SizedBox(width: 14),

              // Timestamp Current
              Text(
                _formatDuration(position),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),

              // Progress Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: AppTheme.successGreen,
                    inactiveTrackColor: AppTheme.successGreen.withValues(alpha: 0.2),
                    thumbColor: AppTheme.successGreen,
                  ),
                  child: Slider(
                    value: position.toDouble(),
                    min: 0.0,
                    max: duration.toDouble(),
                    onChanged: isCurrentActive
                        ? (val) {
                            _player.seekTo(val.round());
                          }
                        : null,
                  ),
                ),
              ),

              // Timestamp Total
              Text(
                _formatDuration(duration),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
