import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API configuration for the School Management app.
///
/// The base URL is resolved from the `API_BASE_URL` compile-time define:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://yallaschool.algoria-wt.com/api
/// ```
///
/// If not provided, the local development LAN host is used. The same LAN URL
/// works from the Android emulator (its NAT routes LAN IPs) and from real
/// devices on the same network — the backend must be started with
/// `php artisan serve --host=0.0.0.0 --port=8000` (loopback-only binding
/// makes the LAN URL unreachable).
class ApiConfig {
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// The single source of truth for the API base URL.
  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && Platform.isAndroid) return 'http://192.168.1.105:8000/api';
    return 'http://192.168.1.105:8000/api';
  }
}