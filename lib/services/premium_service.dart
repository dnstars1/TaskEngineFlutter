import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService extends ChangeNotifier {
  static const _key = 'isPremium';
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> upgrade() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    _isPremium = true;
    notifyListeners();
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    _isPremium = false;
    notifyListeners();
  }
}
