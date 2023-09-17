import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static PreferencesManager? _instance;
  static SharedPreferences? _preferences;

  PreferencesManager._();

  factory PreferencesManager() => _instance ??= PreferencesManager._();

  Future initialize() async {
    _preferences = await SharedPreferences.getInstance();
    SharedPreferences.setMockInitialValues({
      'show_notifications': false,
    });
  }

  static bool? getBool(final String key, [final bool? defaultValue]) {
    return _preferences!.getBool(key) ?? defaultValue;
  }

  static Future<bool> setBool(final String key, final bool value) {
    return _preferences!.setBool(key, value);
  }
}
