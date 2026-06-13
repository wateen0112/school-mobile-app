import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/school_modules.dart';
import '../models/app_models.dart';
import '../network/api_service.dart';
import '../network/auth_service.dart';
import '../network/auth_storage.dart';

/// Notifies [GoRouter] only for auth/role changes — not locale toggles.
class RouterRefreshNotifier extends ChangeNotifier {}

enum AuthStatus { bootstrapping, authenticated, unauthenticated }

class SessionController extends ChangeNotifier {
  SessionController(this._prefs) : authStorage = AuthStorage(_prefs) {
    api = ApiService(authStorage, onUnauthorized: _handleUnauthorized);
    auth = AuthService(api: api, storage: authStorage);
    _restoreFromStorage();
    authStatus = _hasStoredToken
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  }

  final SharedPreferences _prefs;
  final AuthStorage authStorage;
  late final ApiService api;
  late final AuthService auth;
  final RouterRefreshNotifier routerRefresh = RouterRefreshNotifier();

  AppUser? user;
  late Locale locale;
  bool fullscreen = false;
  bool authBusy = false;
  AuthStatus authStatus = AuthStatus.bootstrapping;
  bool _hasStoredToken = false;

  bool get isBootstrapping => authStatus == AuthStatus.bootstrapping;
  bool get isAuthenticated =>
      authStatus == AuthStatus.authenticated && user != null && _hasValidToken;
  bool get _hasValidToken {
    final token = authStorage.token;
    return token != null && token.isNotEmpty;
  }

  UserRole get currentRole => user?.role ?? authStorage.role ?? UserRole.admin;
  bool get isRtl => locale.languageCode == 'ar';
  String get homeRoute =>
      isAuthenticated ? defaultRouteForRole(currentRole) : '/roles';

  Future<void> bootstrap() async {
    if (!_hasStoredToken) {
      _setUnauthenticated();
      return;
    }

    authStatus = AuthStatus.authenticated;
    notifyListeners();
    _notifyRouterRefresh();

    try {
      final profile = await auth.me();
      final role =
          authStorage.role ??
          _parseRole('${profile['type'] ?? profile['guard'] ?? 'admin'}');
      user = _userFromMap(profile, role);
      await _persistUser(user!);
      authStatus = AuthStatus.authenticated;
    } catch (error) {
      final failure = ApiService.failureFrom(error);
      if (failure.statusCode == 401) {
        await _clearLocalSession();
        authStatus = AuthStatus.unauthenticated;
      } else {
        authStatus = AuthStatus.authenticated;
      }
    }

    notifyListeners();
    _notifyRouterRefresh();
  }

  Future<void> selectLocale(Locale value) async {
    if (locale == value) return;
    locale = value;
    await _prefs.setString('locale', value.languageCode);
    notifyListeners();
  }

  void _notifyRouterRefresh() => routerRefresh.notifyListeners();

  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    authBusy = true;
    notifyListeners();
    try {
      final session = await auth.login(
        email: email,
        password: password,
        requestedRole: role,
      );
      _hasStoredToken = true;
      user = AppUser(
        name:
            '${session.user['name'] ?? session.user['Name'] ?? roleLabels[session.role]}',
        email: '${session.user['email'] ?? session.user['Email'] ?? email}',
        role: session.role,
      );
      await _persistUser(user!);
      authStatus = AuthStatus.authenticated;
      _notifyRouterRefresh();
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, UserRole role) async {
    // Registration does not create an API session; user must sign in.
    await _prefs.setString('name', name);
    await _prefs.setString('email', email);
    await _prefs.setString('role', role.name);
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearLocalSession();
    authStatus = AuthStatus.unauthenticated;
    notifyListeners();
    _notifyRouterRefresh();
  }

  Future<void> sessionExpired() async {
    if (authStatus == AuthStatus.unauthenticated) return;
    await _clearLocalSession();
    authStatus = AuthStatus.unauthenticated;
    notifyListeners();
    _notifyRouterRefresh();
  }

  void toggleFullscreen() {
    fullscreen = !fullscreen;
    notifyListeners();
  }

  @override
  void dispose() {
    routerRefresh.dispose();
    super.dispose();
  }

  void _restoreFromStorage() {
    final savedLocale = _prefs.getString('locale');
    locale = Locale(savedLocale ?? 'en');

    _hasStoredToken = _hasValidToken;
    if (!_hasStoredToken) return;

    final storedUser = authStorage.user;
    final storedRole = authStorage.role ?? UserRole.admin;
    user = _userFromMap(storedUser ?? const {}, storedRole);
  }

  AppUser _userFromMap(Map<String, dynamic> map, UserRole role) {
    return AppUser(
      name: '${map['name'] ?? map['Name'] ?? roleLabels[role] ?? role.name}',
      email: '${map['email'] ?? map['Email'] ?? ''}',
      role: role,
    );
  }

  Future<void> _persistUser(AppUser value) async {
    await _prefs.setString('name', value.name);
    await _prefs.setString('email', value.email);
    await _prefs.setString('role', value.role.name);
  }

  Future<void> _clearLocalSession() async {
    user = null;
    _hasStoredToken = false;
    await auth.logout();
    await _prefs.remove('name');
    await _prefs.remove('email');
    await _prefs.remove('role');
  }

  void _setUnauthenticated() {
    user = null;
    _hasStoredToken = false;
    authStatus = AuthStatus.unauthenticated;
    notifyListeners();
    _notifyRouterRefresh();
  }

  void _handleUnauthorized() {
    sessionExpired();
  }

  UserRole _parseRole(String value) {
    final normalized = value.toLowerCase().replaceAll('web', 'admin');
    return UserRole.values.firstWhere(
      (role) => role.name == normalized,
      orElse: () => UserRole.admin,
    );
  }
}
