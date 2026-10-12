import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/school_modules.dart';
import '../localization/error_messages.dart';
import '../models/app_models.dart';
import '../network/api_service.dart';
import '../network/auth_service.dart';
import '../../features/transportation/services/driver_location_foreground_service.dart';
import '../../features/transportation/services/gps_queue_store.dart';
import '../network/auth_storage.dart';
import '../network/background_notification_service.dart';
import '../network/foreground_notification_poller.dart';
import '../network/notification_service.dart';

/// Notifies [GoRouter] only for auth/role changes — not locale toggles.
class RouterRefreshNotifier extends ChangeNotifier {}

enum AuthStatus { bootstrapping, authenticated, unauthenticated }

class SessionController extends ChangeNotifier {
  SessionController(this._prefs) : authStorage = AuthStorage(_prefs) {
    showChucker = _prefs.getBool(_chuckerKey) ?? false;
    api = ApiService(
      authStorage,
      onUnauthorized: _handleUnauthorized,
      showChucker: showChucker,
    );
    auth = AuthService(api: api, storage: authStorage);
    notifications = NotificationService(api: api);
    _foregroundPoller = ForegroundNotificationPoller(
      storage: authStorage,
      onCountChanged: (count) {
        unreadNotificationCount = count;
        notifyListeners();
      },
      interval: const Duration(seconds: 30),
    );
    _restoreFromStorage();
    // Keep bootstrapping until bootstrap() is explicitly called
    // This allows the splash screen to show during initial load
  }

  static const _chuckerKey = 'show_chucker';

  final SharedPreferences _prefs;
  final AuthStorage authStorage;
  late final ApiService api;
  late final AuthService auth;
  late final NotificationService notifications;
  late final ForegroundNotificationPoller _foregroundPoller;
  final RouterRefreshNotifier routerRefresh = RouterRefreshNotifier();

  AppUser? user;
  late Locale locale;
  bool showChucker = false;
  bool fullscreen = false;
  bool authBusy = false;
  AuthStatus authStatus = AuthStatus.bootstrapping;
  bool _hasStoredToken = false;
  int unreadNotificationCount = 0;

  bool get isBootstrapping => authStatus == AuthStatus.bootstrapping;
  bool get isAuthenticated =>
      authStatus == AuthStatus.authenticated && user != null && _hasValidToken;
  bool get _hasValidToken {
    final token = authStorage.token;
    return token != null && token.isNotEmpty;
  }

  UserRole get currentRole =>
      user?.role ?? authStorage.role ?? UserRole.teacher;
  bool get isRtl => locale.languageCode == 'ar';
  String get homeRoute =>
      isAuthenticated ? defaultRouteForRole(currentRole) : '/login';

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
          _parseRole('${profile['type'] ?? profile['guard'] ?? 'teacher'}');
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
    refreshUnreadCount();

    // Start FCM notification service when authenticated
    if (authStatus == AuthStatus.authenticated) {
      await BackgroundNotificationService.startPolling();
      // Get FCM token and register with backend
      await _registerFcmToken();
    }

    // Start foreground notification polling when authenticated
    if (authStatus == AuthStatus.authenticated) {
      _foregroundPoller.start();
    }
  }

  Future<void> selectLocale(Locale value) async {
    if (locale == value) return;
    locale = value;
    ErrorLocale.languageCode = value.languageCode;
    await _prefs.setString('locale', value.languageCode);
    notifyListeners();
  }

  void _notifyRouterRefresh() => routerRefresh.notifyListeners();

  Future<void> login({
    required String email,
    required String password,
    String? type,
  }) async {
    authBusy = true;
    notifyListeners();
    try {
      final session = await auth.login(
        email: email,
        password: password,
        type: type,
      );
      _hasStoredToken = true;
      user = AppUser(
        id: _parseId(session.user['id'] ?? session.user['ID']),
        name:
            '${session.user['name'] ?? session.user['Name'] ?? roleLabels[session.role]}',
        email: '${session.user['email'] ?? session.user['Email'] ?? email}',
        role: session.role,
      );
      await _persistUser(user!);
      authStatus = AuthStatus.authenticated;
      refreshUnreadCount();
      // Start FCM notification service
      await BackgroundNotificationService.startPolling();
      // Register FCM token with backend
      await _registerFcmToken();
      // Start foreground notification polling
      _foregroundPoller.start();
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
    // Set unauthenticated status immediately so the UI updates right away
    user = null;
    _hasStoredToken = false;
    unreadNotificationCount = 0;
    authStatus = AuthStatus.unauthenticated;
    notifyListeners();
    _notifyRouterRefresh();

    // Perform cleanup operations in the background
    Future.microtask(() async {
      await _clearLocalSession();
    });
  }

  Future<void> sessionExpired() async {
    if (authStatus == AuthStatus.unauthenticated) return;
    await _clearLocalSession();
    authStatus = AuthStatus.unauthenticated;
    notifyListeners();
    _notifyRouterRefresh();
  }

  Future<void> toggleChucker() async {
    showChucker = !showChucker;
    await _prefs.setBool(_chuckerKey, showChucker);
    notifyListeners();
  }

  Future<void> toggleFullscreen() async {
    fullscreen = !fullscreen;
    notifyListeners();
  }

  /// Update the in-memory user from a successful profile update.
  void updateUserFromProfile({String? name, String? email}) {
    if (user == null) return;
    user = AppUser(
      id: user!.id,
      name: name ?? user!.name,
      email: email ?? user!.email,
      role: user!.role,
    );
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadNotificationCount = await notifications.getUnreadCount();
      notifyListeners();
    } catch (_) {
      unreadNotificationCount = 0;
    }
  }

  @override
  void dispose() {
    _foregroundPoller.stop();
    routerRefresh.dispose();
    super.dispose();
  }

  void _restoreFromStorage() {
    final savedLocale = _prefs.getString('locale');
    locale = Locale(savedLocale ?? 'ar');
    ErrorLocale.languageCode = locale.languageCode;
    showChucker = _prefs.getBool(_chuckerKey) ?? false;

    // Restore _hasStoredToken from auth storage
    _hasStoredToken = _hasValidToken;
    if (!_hasStoredToken) return;

    final storedUser = authStorage.user;
    final storedRole = authStorage.role ?? UserRole.teacher;
    final storedId = _prefs.getInt('user_id');
    final map = Map<String, dynamic>.from(storedUser ?? const {});
    if (storedId != null && !map.containsKey('id')) {
      map['id'] = storedId;
    }
    user = _userFromMap(map, storedRole);
  }

  AppUser _userFromMap(Map<String, dynamic> map, UserRole role) {
    return AppUser(
      id: _parseId(map['id'] ?? map['ID']),
      name: '${map['name'] ?? map['Name'] ?? roleLabels[role] ?? role.name}',
      email: '${map['email'] ?? map['Email'] ?? ''}',
      role: role,
    );
  }

  Future<void> _persistUser(AppUser value) async {
    if (value.id != null) {
      await _prefs.setInt('user_id', value.id!);
    }
    await _prefs.setString('name', value.name);
    await _prefs.setString('email', value.email);
    await _prefs.setString('role', value.role.name);
  }

  Future<void> _clearLocalSession() async {
    user = null;
    _hasStoredToken = false;

    // Stop any active driver-trip tracking (the foreground service would
    // otherwise keep posting with a token that is about to die).
    try {
      await DriverLocationForegroundService.stop();
      await ActiveTripStore.clear();
    } catch (_) {
      // Best-effort cleanup — never block logout.
    }

    // Clear local storage first (synchronous operations)
    await _prefs.remove('user_id');
    await _prefs.remove('name');
    await _prefs.remove('email');
    await _prefs.remove('role');

    // Clear auth token (this may involve network calls, but auth.logout handles it)
    await auth.logout();

    // Delete FCM token
    await deleteFcmToken();

    // Stop polling services
    _foregroundPoller.stop();
    await BackgroundNotificationService.stopPolling();
    await BackgroundNotificationService.clearLastSeen();
  }

  int? _parseId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
    final normalized = value.toLowerCase();
    return UserRole.values.firstWhere(
      (role) => role.name == normalized,
      orElse: () => UserRole.teacher,
    );
  }

  /// Get FCM token and send it to the backend
  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await getAndStoreFcmToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await api.post('/register-fcm-token', data: {'token': fcmToken});
      }
    } catch (_) {
      // Silently fail - FCM token registration is best-effort
    }
  }
}
