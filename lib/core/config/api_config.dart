/// Default API host for devices on the same LAN as the dev machine (Wi-Fi).
/// Update [lanHost] when your machine's IPv4 changes (`ipconfig` on Windows).
class ApiConfig {
  static const lanHost = 'https://yallaschool.algoria-wt.com/api';
  static const port = 8000;
  static const defaultBaseUrl = lanHost;
}
