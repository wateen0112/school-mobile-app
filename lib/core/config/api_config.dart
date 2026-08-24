import 'dart:io';

/// API configuration for the School Management app.
/// Supports multiple environments: development, local network, and production.
///
/// PRODUCTION HOST: https://yallaschool.algoria-wt.com
/// The live Laravel backend is deployed on Hostinger.
class ApiConfig {
  // static const lanHost = 'https://yallaschool.algoria-wt.com/api';
  static const lanHost = 'http://192.168.1.101:8000/api';

  static const port = 8000;
  static const defaultBaseUrl = lanHost;
}
