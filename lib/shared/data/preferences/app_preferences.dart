import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _themeKey = 'theme_mode';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _autoSyncKey = 'auto_sync';
  static const String _aiAnalysisKey = 'ai_analysis_enabled';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _encryptionEnabledKey = 'encryption_enabled';

  Future<void> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
  }

  Future<bool> getAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncKey) ?? true;
  }

  Future<void> setAIAnalysisEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiAnalysisKey, enabled);
  }

  Future<bool> getAIAnalysisEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiAnalysisKey) ?? true;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastSyncKey);
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  Future<void> setEncryptionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_encryptionEnabledKey, enabled);
  }

  Future<bool> getEncryptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_encryptionEnabledKey) ?? true;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}