import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_service.dart';
import '../network/auth_storage.dart';
import '../network/background_notification_service.dart';
import '../network/notification_service.dart';

/// Foreground notification polling service.
///
/// Polls the unread notifications count every [interval] and invokes
/// [onCountChanged] whenever the value changes. Also fetches the actual
/// unread notification details and shows local notification popups for
/// any new ones.
class ForegroundNotificationPoller {
  ForegroundNotificationPoller({
    required AuthStorage storage,
    required this.onCountChanged,
    this.interval = const Duration(seconds: 30),
  }) : _api = ApiService(
          storage,
          onUnauthorized: () {},
          showChucker: false,
        );

  final ApiService _api;
  final void Function(int count) onCountChanged;
  final Duration interval;

  Timer? _timer;
  int _lastCount = 0;
  Set<int> _lastSeenIds = <int>{};
  bool _firstTick = true;

  static const String _lastSeenIdsKey = 'foreground_poller.last_seen_ids';

  /// Start polling.
  void start() {
    stop();
    _loadLastSeenIds().then((_) {
      _tick();
      _timer = Timer.periodic(interval, (_) => _tick());
    });
  }

  /// Stop polling.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether polling is currently active.
  bool get isRunning => _timer != null && _timer!.isActive;

  Future<void> _loadLastSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_lastSeenIdsKey);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        _lastSeenIds = list.map((e) => e as int).toSet();
      }
    } catch (_) {
      _lastSeenIds = <int>{};
    }
  }

  Future<void> _saveLastSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSeenIdsKey, jsonEncode(_lastSeenIds.toList()));
    } catch (_) {}
  }

  Future<void> _tick() async {
    try {
      final service = NotificationService(api: _api);

      // Fetch unread count
      final count = await service.getUnreadCount();

      // Fetch actual unread notifications to show popups
      final unreadNotifications = await service.getUnreadNotifications();

      final currentIds = <int>{};
      int newCount = 0;

      for (final item in unreadNotifications) {
        currentIds.add(item.id);

        // On first tick, just record IDs without showing notifications
        // to avoid flooding the user on app startup
        if (!_firstTick && !_lastSeenIds.contains(item.id)) {
          await showNotification(
            id: item.id,
            title: item.title,
            body: item.body,
            payload: jsonEncode({'notification_id': item.id}),
          );
          newCount++;
        }
      }

      _lastSeenIds = currentIds;
      _firstTick = false;
      await _saveLastSeenIds();

      // Update badge count if changed
      if (count != _lastCount) {
        _lastCount = count;
        onCountChanged(count);
      }
    } catch (_) {
      // Silently ignore errors so polling doesn't crash the app
    }
  }
}
