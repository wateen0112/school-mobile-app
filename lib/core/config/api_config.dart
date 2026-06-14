import dart:io;

/// API configuration for the School Management app.
/// Supports multiple environments: development, local network, and production.
///
/// PRODUCTION HOST: https://yallaschool.algoria-wt.com
/// The live Laravel backend is deployed on Hostinger.
class ApiConfig {
  static const _devHost = localhost;
  static const _devPort = 8000;

  /// Android emulator loopback to host
  static const _androidEmulatorHost = 10.0.2.2;

  /// iOS simulator loopback to host
  static const _iosSimulatorHost = 127.0.0.1;

  /// LIVE PRODUCTION HOST - Hostinger VPS
  static const _prodHost = yallaschool.algoria-wt.com;

  /// Production flag
  static const bool isProduction = bool.fromEnvironment(dart.vm.product);

  /// Default base URL for fallback
  static String get defaultBaseUrl => baseUrl;

  /// Choose the correct base URL depending on the platform and environment.
  static String get baseUrl {
    // Production / web builds - use the LIVE Hostinger backend
    if (isProduction || isWeb) {
      return https:///api;
    }

    // Mobile development builds
    final host = _selectDevHost();
    return http://:/api;
  }

  static bool get isWeb => identical(0, 0.0);

  static String _selectDevHost() {
    try {
      if (Platform.isAndroid) return _androidEmulatorHost;
      if (Platform.isIOS) return _iosSimulatorHost;
      return _devHost;
    } catch (_) {
      // Web environment
      return https:///api;
    }
  }

  /// Media files base URL
  static String get mediaBaseUrl {
    return baseUrl.replaceAll(/api, /storage);
  }

  /// Student images URL
  static String studentImageUrl(String imageName) {
    return $mediaBaseUrl/students/$imageName;
  }

  /// Parent images URL
  static String parentImageUrl(String imageName) {
    return $mediaBaseUrl/parents/$imageName;
  }

  /// Teacher images URL
  static String teacherImageUrl(String imageName) {
    return $mediaBaseUrl/teachers/$imageName;
  }

  /// Admin images URL
  static String adminImageUrl(String imageName) {
    return $mediaBaseUrl/admin/$imageName;
  }

  /// School logo URL
  static String get schoolLogoUrl {
    return $mediaBaseUrl/school_logo.png;
  }

  /// Default avatar for users without a profile picture
  static String get defaultAvatarUrl {
    return $mediaBaseUrl/default-avatar.png;
  }
}
