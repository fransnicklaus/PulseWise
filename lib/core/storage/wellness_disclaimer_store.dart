import 'package:shared_preferences/shared_preferences.dart';

class WellnessDisclaimerStore {
  WellnessDisclaimerStore._();

  static const String acknowledgmentPrefsKey =
      'wellness_disclaimer_acknowledged_v1';

  static Future<bool> isAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(acknowledgmentPrefsKey) ?? false;
  }

  static Future<void> markAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(acknowledgmentPrefsKey, true);
  }
}
