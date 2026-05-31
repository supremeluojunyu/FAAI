import 'package:shared_preferences/shared_preferences.dart';

class ConfigStorage {
  static const _keyApiBase = 'manual_api_base_url';
  static const _keyWsUrl = 'manual_ws_url';

  static Future<String?> getSavedApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiBase);
  }

  static Future<String?> getSavedWsUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWsUrl);
  }

  static Future<void> saveManualConfig({
    required String apiBaseUrl,
    required String wsUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiBase, apiBaseUrl);
    await prefs.setString(_keyWsUrl, wsUrl);
  }

  static Future<void> clearManualConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiBase);
    await prefs.remove(_keyWsUrl);
  }
}
