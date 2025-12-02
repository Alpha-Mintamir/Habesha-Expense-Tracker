import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

/// Service for managing PIN lock functionality
class PinService {
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinLockTimeKey = 'pin_lock_time';

  /// Set a new PIN (hashes it before storing)
  Future<bool> setPin(String pin) async {
    if (pin.length < 4 || pin.length > 6) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);

      await prefs.setString(_pinHashKey, hash);
      await prefs.setString(_pinSaltKey, salt);
      await prefs.setBool(_pinEnabledKey, true);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify a PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_pinHashKey);
      final salt = prefs.getString(_pinSaltKey);

      if (storedHash == null || salt == null) {
        return false;
      }

      final computedHash = _hashPin(pin, salt);
      return storedHash == computedHash;
    } catch (e) {
      return false;
    }
  }

  /// Check if PIN is enabled
  Future<bool> hasPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pinEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Disable PIN lock (requires current PIN)
  Future<bool> disablePin(String currentPin) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pinEnabledKey, false);
      await prefs.remove(_pinHashKey);
      await prefs.remove(_pinSaltKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change PIN (requires current PIN)
  Future<bool> changePin(String currentPin, String newPin) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      return false;
    }

    return await setPin(newPin);
  }

  /// Clear PIN (for logout/reset scenarios)
  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, false);
    await prefs.remove(_pinHashKey);
    await prefs.remove(_pinSaltKey);
  }

  /// Save the time when app was locked
  Future<void> saveLockTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pinLockTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if PIN lock should be shown.
  /// For this app we keep it simple: if a PIN is enabled, show the lock screen
  /// on app start. The timeout value is currently ignored.
  Future<bool> shouldShowLock({Duration timeout = const Duration(minutes: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_pinEnabledKey) ?? false;
    return enabled;
  }

  /// Simple hash function (for basic security)
  String _hashPin(String pin, String salt) {
    final combined = '$pin$salt';
    final bytes = utf8.encode(combined);
    // Simple hash - in production, use crypto library
    var hash = 0;
    for (var byte in bytes) {
      hash = ((hash << 5) - hash) + byte;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString();
  }

  /// Generate a random salt
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }
}


