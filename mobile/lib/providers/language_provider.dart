import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // Initialize language from shared preferences
  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  void setLanguage(Locale locale) async {
    if (!['en', 'fr'].contains(locale.languageCode)) {
      return; // Only allow English and French
    }

    _locale = locale;
    notifyListeners();

    // Save to shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  void setEnglish() => setLanguage(const Locale('en'));
  void setFrench() => setLanguage(const Locale('fr'));
}
