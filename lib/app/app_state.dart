import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.state, required super.child});

  final AppState state;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.state != state;
}

class AppState extends ChangeNotifier {
  AppState(this._prefs)
    : locale = Locale(_prefs.getString(_localeKey) ?? 'en'),
      token = _prefs.getString(_tokenKey),
      userName = _prefs.getString(_userNameKey),
      userType = _prefs.getString(_userTypeKey),
      baseUrl = _prefs.getString(_baseUrlKey) ?? ApiConfig.defaultBaseUrl,
      hasSeenOnboarding = _prefs.getBool(_onboardingKey) ?? false;

  static const _localeKey = 'locale';
  static const _tokenKey = 'access_token';
  static const _userNameKey = 'user_name';
  static const _userTypeKey = 'user_type';
  static const _baseUrlKey = 'base_url';
  static const _onboardingKey = 'has_seen_onboarding';

  final SharedPreferences _prefs;

  Locale locale;
  String? token;
  String? userName;
  String? userType;
  String baseUrl;
  bool hasSeenOnboarding;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get isArabic => locale.languageCode == 'ar';

  Future<void> setLocale(Locale value) async {
    locale = value;
    await _prefs.setString(_localeKey, value.languageCode);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> setBaseUrl(String value) async {
    baseUrl = value.trim().replaceFirst(RegExp(r'/+$'), '');
    await _prefs.setString(_baseUrlKey, baseUrl);
    notifyListeners();
  }

  Future<void> signIn({
    required String accessToken,
    required String name,
    required String type,
  }) async {
    token = accessToken;
    userName = name;
    userType = type;
    await _prefs.setString(_tokenKey, accessToken);
    await _prefs.setString(_userNameKey, name);
    await _prefs.setString(_userTypeKey, type);
    notifyListeners();
  }

  Future<void> signOut() async {
    token = null;
    userName = null;
    userType = null;
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_userTypeKey);
    notifyListeners();
  }
}
