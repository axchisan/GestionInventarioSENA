import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  static LanguageService get instance => _instance;
  LanguageService._internal();

  static const String _languageKey = 'language_code';
  
  Locale _currentLocale = const Locale('es', 'ES');
  Locale get currentLocale => _currentLocale;

  final List<Locale> supportedLocales = const [
    Locale('es', 'ES'),
    Locale('en', 'US'),
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'es';
    _currentLocale = Locale(languageCode, languageCode == 'es' ? 'ES' : 'US');
    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }
}
