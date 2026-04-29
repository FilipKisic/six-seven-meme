import 'package:shared_preferences/shared_preferences.dart';

class TapCounterStorage {
  static const int tapsPerInterstitial = 5;
  static const String _tapCountKey = 'meme_tap_count';

  Future<bool> registerTapAndShouldShowInterstitial() async {
    final preferences = await SharedPreferences.getInstance();
    final tapCount = (preferences.getInt(_tapCountKey) ?? 0) + 1;

    if (tapCount >= tapsPerInterstitial) {
      await preferences.setInt(_tapCountKey, 0);
      return true;
    }

    await preferences.setInt(_tapCountKey, tapCount);
    return false;
  }
}
