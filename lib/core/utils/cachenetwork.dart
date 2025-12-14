import 'package:shared_preferences/shared_preferences.dart';

class Cachenetwork {
  static late SharedPreferences _prefs;
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  static Future<bool> insert(String key, String value) async {
    await init();
    return await _prefs.setString(key, value);
  }

  static String getdata(String key) {
    if (!_initialized) return "";
    return _prefs.getString(key) ?? "";
  }

  static Future<bool> delete(String key) async {
    await init();
    return await _prefs.remove(key);
  }

  static bool contains(String key) {
    if (!_initialized) return false;
    return _prefs.containsKey(key);
  }
  
}
