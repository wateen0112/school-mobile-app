import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/app_models.dart';

class AuthStorage {
  AuthStorage(this._prefs);

  static const _tokenKey = 'auth.token';
  static const _userKey = 'auth.user';
  static const _roleKey = 'auth.role';
  static const _baseUrlKey = 'api.base_url';

  static final defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  final SharedPreferences _prefs;

  String get baseUrl => _prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  String? get token => _prefs.getString(_tokenKey);
  Map<String, dynamic>? get user {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  UserRole? get role {
    final value = _prefs.getString(_roleKey);
    if (value == null) return null;
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.admin,
    );
  }

  Future<void> setBaseUrl(String value) async {
    await _prefs.setString(
      _baseUrlKey,
      value.trim().replaceFirst(RegExp(r'/+$'), ''),
    );
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
    required UserRole role,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(user));
    await _prefs.setString(_roleKey, role.name);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    await _prefs.remove(_roleKey);
  }
}
