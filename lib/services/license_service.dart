import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// License Status Enum
enum LicenseStatus {
  /// Permanent Lifetime License active
  activated,
  /// 7-day trial currently active
  trialActive,
  /// 7-day trial period expired - access locked
  trialExpired,
}

/// Service managing device hardware identification, 7-day trial period,
/// tamper-resistant trial timestamps, and cryptographic HMAC-SHA256 license activation.
class LicenseService extends ChangeNotifier {
  static const String _keyDeviceSeed = 'license_device_seed';
  static const String _keyFirstRunEpoch = 'license_first_run_epoch';
  static const String _keyFirstRunSig = 'license_first_run_sig';
  static const String _keyActivationKey = 'license_activation_key';
  static const String _keyActivationSig = 'license_activation_sig';

  /// Master cryptographic secret salt for the Bayan Educational Platform
  static const String masterSecret = 'BAYAN_PRIMARY_ARABIC_2026_MASTER_SECRET_KEY';

  /// Trial duration: 7 days
  static const Duration trialDuration = Duration(days: 7);

  SharedPreferences? _prefs;

  String _deviceCode = '';
  bool _isActivated = false;
  DateTime _firstRunDate = DateTime.now();
  bool _isClockTampered = false;

  /// Human-readable, unique device identifier (e.g. BYN-675B-A8C1-7BFB)
  String get deviceCode => _deviceCode;

  /// Whether the permanent license has been activated
  bool get isActivated => _isActivated;

  /// Date when the application was first launched on this device
  DateTime get firstRunDate => _firstRunDate;

  /// Expiration date of the 7-day trial period
  DateTime get trialExpiryDate => _firstRunDate.add(trialDuration);

  /// Time remaining in the trial period
  Duration get timeRemaining {
    if (_isActivated) return Duration.zero;
    final now = DateTime.now();
    final remaining = trialExpiryDate.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Remaining whole days in trial (0 to 7)
  int get daysRemaining {
    if (_isActivated) return 0;
    final rem = timeRemaining;
    if (rem == Duration.zero) return 0;
    // Add 1 day if hours remaining > 0 for friendly display (e.g. 6 days and 20 hours shows 7 or 6)
    return rem.inDays + (rem.inHours % 24 > 0 ? 1 : 0);
  }

  /// Whether the 7-day trial period is currently active and unexpired
  bool get isTrialActive {
    if (_isActivated) return false;
    if (_isClockTampered) return false;
    return DateTime.now().isBefore(trialExpiryDate);
  }

  /// Whether the trial has expired and the app is not activated
  bool get isTrialExpired {
    if (_isActivated) return false;
    return !isTrialActive;
  }

  /// Current license status
  LicenseStatus get status {
    if (_isActivated) return LicenseStatus.activated;
    if (isTrialActive) return LicenseStatus.trialActive;
    return LicenseStatus.trialExpired;
  }

  /// Gatekeeper permission: allows access to lessons and interactive exercises
  /// only when permanently activated OR within the 7-day trial period.
  bool get canAccessCurriculum => _isActivated || isTrialActive;

  /// Initializes hardware ID, checks trial status, and verifies existing license.
  Future<void> init({SharedPreferences? prefs}) async {
    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      await _initDeviceCode();
      await _checkTrialState();
      await _verifyExistingActivation();
    } catch (e) {
      debugPrint('LicenseService initialization fallback: $e');
      if (_deviceCode.isEmpty) {
        _deviceCode = 'BYN-GENERIC-FALLBACK';
      }
    }
    notifyListeners();
  }

  /// Generates or loads the persistent, hardware-linked Device Code.
  Future<void> _initDeviceCode() async {
    String rawHardwareId = '';

    // On Windows, retrieve MachineGuid from Windows Registry
    if (!kIsWeb && Platform.isWindows) {
      try {
        final result = Process.runSync('reg', [
          'query',
          r'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography',
          '/v',
          'MachineGuid',
        ]);
        if (result.exitCode == 0) {
          final stdout = result.stdout.toString();
          final match = RegExp(r'MachineGuid\s+REG_SZ\s+([a-zA-Z0-9\-]+)').firstMatch(stdout);
          if (match != null) {
            rawHardwareId = match.group(1) ?? '';
          }
        }
      } catch (e) {
        debugPrint('Registry query fallback: $e');
      }
    }

    // If registry query is empty or non-Windows, use persistent random seed
    if (rawHardwareId.isEmpty) {
      String? savedSeed = _prefs?.getString(_keyDeviceSeed);
      if (savedSeed == null || savedSeed.isEmpty) {
        final randomBytes = List<int>.generate(16, (i) => (DateTime.now().microsecondsSinceEpoch + i * 31) % 256);
        savedSeed = sha256.convert(randomBytes).toString();
        await _prefs?.setString(_keyDeviceSeed, savedSeed);
      }
      rawHardwareId = savedSeed;
    }

    // Hash the hardware identifier with salt and format as BYN-XXXX-XXXX-XXXX
    final hash = sha256.convert(utf8.encode('BAYAN_HWID_$rawHardwareId')).toString().toUpperCase();
    final block1 = hash.substring(0, 4);
    final block2 = hash.substring(4, 8);
    final block3 = hash.substring(8, 12);
    _deviceCode = 'BYN-$block1-$block2-$block3';
  }

  /// Initializes and verifies the 7-day trial period timestamps with anti-tamper signature.
  Future<void> _checkTrialState() async {
    final now = DateTime.now();
    final savedEpoch = _prefs?.getInt(_keyFirstRunEpoch);
    final savedSig = _prefs?.getString(_keyFirstRunSig);

    if (savedEpoch == null || savedSig == null) {
      // First run: save timestamp and HMAC anti-tamper signature
      final epoch = now.millisecondsSinceEpoch;
      final sig = _computeHmac('$epoch|$_deviceCode|FIRST_RUN');
      await _prefs?.setInt(_keyFirstRunEpoch, epoch);
      await _prefs?.setString(_keyFirstRunSig, sig);
      _firstRunDate = now;
      _isClockTampered = false;
    } else {
      // Verify signature to prevent manual preferences tampering
      final expectedSig = _computeHmac('$savedEpoch|$_deviceCode|FIRST_RUN');
      if (savedSig != expectedSig) {
        debugPrint('Trial timestamp signature mismatch: tampering detected.');
        _isClockTampered = true;
        _firstRunDate = now.subtract(trialDuration + const Duration(days: 1));
      } else {
        _firstRunDate = DateTime.fromMillisecondsSinceEpoch(savedEpoch);
        // Detect backward clock manipulation (more than 2 hours in the past)
        if (now.isBefore(_firstRunDate.subtract(const Duration(hours: 2)))) {
          debugPrint('Clock rollback detected.');
          _isClockTampered = true;
        }
      }
    }
  }

  /// Verifies if a valid activation key is already stored.
  Future<void> _verifyExistingActivation() async {
    final savedKey = _prefs?.getString(_keyActivationKey);
    final savedSig = _prefs?.getString(_keyActivationSig);

    if (savedKey != null && savedSig != null) {
      if (verifyKey(_deviceCode, savedKey)) {
        final expectedSig = _computeHmac('$_deviceCode|$savedKey|VALID_KEY');
        if (savedSig == expectedSig) {
          _isActivated = true;
          return;
        }
      }
    }
    _isActivated = false;
  }

  /// Validates and applies an activation code entered by the user.
  /// Returns true if activation succeeded, false otherwise.
  Future<bool> activate(String enteredKey) async {
    final cleanKey = normalizeKey(enteredKey);
    if (cleanKey.isEmpty) return false;

    if (verifyKey(_deviceCode, cleanKey)) {
      _isActivated = true;
      if (_prefs != null) {
        final sig = _computeHmac('$_deviceCode|$cleanKey|VALID_KEY');
        await _prefs!.setString(_keyActivationKey, cleanKey);
        await _prefs!.setString(_keyActivationSig, sig);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Alias for activate
  Future<bool> activateSoftware(String enteredKey) => activate(enteredKey);

  /// Removes activation and trial state (used primarily in test suites).
  Future<void> clearForTesting() async {
    _isActivated = false;
    _isClockTampered = false;
    _firstRunDate = DateTime.now();
    if (_prefs != null) {
      await _prefs!.remove(_keyActivationKey);
      await _prefs!.remove(_keyActivationSig);
      await _prefs!.remove(_keyFirstRunEpoch);
      await _prefs!.remove(_keyFirstRunSig);
    }
    notifyListeners();
  }

  /// Forces trial to expired state (used in testing).
  Future<void> expireTrialForTesting() async {
    _isActivated = false;
    _firstRunDate = DateTime.now().subtract(const Duration(days: 8));
    if (_prefs != null) {
      final epoch = _firstRunDate.millisecondsSinceEpoch;
      final sig = _computeHmac('$epoch|$_deviceCode|FIRST_RUN');
      await _prefs!.setInt(_keyFirstRunEpoch, epoch);
      await _prefs!.setString(_keyFirstRunSig, sig);
      await _prefs!.remove(_keyActivationKey);
      await _prefs!.remove(_keyActivationSig);
    }
    notifyListeners();
  }

  /// Computes HMAC-SHA256 signature using the Master Secret.
  static String _computeHmac(String data) {
    final hmac = Hmac(sha256, utf8.encode(masterSecret));
    return hmac.convert(utf8.encode(data)).toString().toUpperCase();
  }

  /// Generates the official activation key for a given device code.
  /// Used by the author's Keygen algorithm (Python, PowerShell, and Dart).
  static String generateActivationKey(String deviceCode) {
    final normalized = normalizeDeviceCode(deviceCode);
    final hmac = Hmac(sha256, utf8.encode(masterSecret));
    final digest = hmac.convert(utf8.encode(normalized)).toString().toUpperCase();

    // 16 Hex characters formatted into 4 blocks of 4
    final b1 = digest.substring(0, 4);
    final b2 = digest.substring(4, 8);
    final b3 = digest.substring(8, 12);
    final b4 = digest.substring(12, 16);

    return 'ACT-$b1-$b2-$b3-$b4';
  }

  /// Cryptographically verifies whether an activation key matches a device code.
  static bool verifyKey(String deviceCode, String activationKey) {
    final expected = generateActivationKey(deviceCode);
    final normalizedInput = normalizeKey(activationKey);
    final normalizedExpected = normalizeKey(expected);

    return normalizedInput == normalizedExpected;
  }

  /// Normalizes Device Code (removes spaces, enforces uppercase).
  static String normalizeDeviceCode(String input) {
    return input.trim().toUpperCase();
  }

  /// Normalizes Activation Key (strips spaces, dashes, optional ACT- prefix).
  static String normalizeKey(String input) {
    String clean = input.trim().toUpperCase().replaceAll(' ', '').replaceAll('-', '');
    if (clean.startsWith('ACT')) {
      clean = clean.substring(3);
    }
    return clean;
  }
}
