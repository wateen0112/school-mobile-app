/// Default API host for devices on the same LAN as the dev machine (Wi-Fi).
/// Update [lanHost] when your machine's IPv4 changes (`ipconfig` on Windows).
class ApiConfig {
  static const lanHost = '192.168.1.105';
  static const port = 8000;
  static const defaultBaseUrl = 'http://$lanHost:$port/api';
}
