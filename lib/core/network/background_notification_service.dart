import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/notification_navigation.dart';
import '../router/app_navigator.dart';
import 'api_service.dart';
import 'auth_storage.dart';

/// Notification channel ID for actual school notifications
const String _schoolChannelId = 'school_notifications_channel';
const String _schoolChannelName = 'School Notifications';
const String _schoolChannelDesc = 'Notifications from School Management System';

/// Key for storing FCM token
const String _fcmTokenKey = 'fcm_token';

/// Key for storing last seen notification IDs
const String _lastSeenIdsKey = 'notifications.last_seen_ids';

/// Singleton for local notifications plugin
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showLocalNotificationFromRemote(message);
}

/// Show local notification from FCM remote message
Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  final title = notification?.title ?? data['title'] ?? 'New Notification';
  final body = notification?.body ?? data['body'] ?? '';
  final id = int.tryParse('${data['id'] ?? message.messageId}') ?? DateTime.now().millisecond;

  await showNotification(
    id: id,
    title: title,
    body: body,
    payload: jsonEncode(data),
  );
}

/// Handle notification tap payloads and route to the appropriate screen.
void _handleNotificationPayload(String payload) {
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final route = routeForNotificationPayload(data);
    if (route == null) return;

    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final path = route.$1;
    final extra = route.$2;

    if (path == '/my-installments') {
      _navigateToMyInstallments(installmentId: extra as int?);
    } else if (path == '/notifications') {
      context.push('/notifications');
    } else {
      context.push(path);
    }
  } catch (_) {
    // Ignore malformed payloads.
  }
}

void _navigateToMyInstallments({int? installmentId}) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;

  context.push('/my-installments', extra: installmentId);
}

/// Initialize Firebase and local notifications
Future<void> initializeNotifications() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Request permission (iOS)
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
    // Try to register with backend if we have auth
    try {
      final storage = AuthStorage(prefs);
      final apiToken = storage.token;
      if (apiToken != null && apiToken.isNotEmpty) {
        final api = ApiService(
          storage,
          onUnauthorized: () {},
          showChucker: false,
        );
        await api.post('/register-fcm-token', data: {'token': token});
      }
    } catch (_) {
      // Silently fail - will retry on next login
    }
  });

  // Initialize local notifications
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload case final payload?) {
        _handleNotificationPayload(payload);
      }
    },
  );

  // Create Android notification channel
  if (Platform.isAndroid) {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _schoolChannelId,
        _schoolChannelName,
        description: _schoolChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  // Listen to foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showLocalNotificationFromRemote(message);
  });

  // Handle when app opened from notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationPayload(jsonEncode(message.data));
  });
}

/// Get and store FCM token
Future<String?> getAndStoreFcmToken() async {
  try {
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
    }
    return token;
  } catch (e) {
    return null;
  }
}

/// Get stored FCM token
Future<String?> getStoredFcmToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_fcmTokenKey);
}

/// Delete FCM token (e.g., on logout)
Future<void> deleteFcmToken() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.deleteToken();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_fcmTokenKey);
}

/// Show a local system notification
Future<void> showNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  final androidDetails = AndroidNotificationDetails(
    _schoolChannelId,
    _schoolChannelName,
    channelDescription: _schoolChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    icon: '@mipmap/ic_launcher',
    styleInformation: body.length > 50
        ? BigTextStyleInformation(body)
        : null,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _localNotifications.show(id, title, body, details, payload: payload);
}

/// Poll notifications from API and show local notifications for new ones (fallback)
Future<void> _pollAndNotify() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storage = AuthStorage(prefs);
    final token = storage.token;

    if (token == null || token.isEmpty) {
      return;
    }

    final api = ApiService(
      storage,
      onUnauthorized: () {},
      showChucker: false,
    );

    final response = await api.get('/my-notifications', query: {'unread_only': '1'});
    final data = response['data'] ?? response;

    if (data is! List || data.isEmpty) {
      return;
    }

    final lastSeenJson = prefs.getString(_lastSeenIdsKey);
    final Set<int> lastSeenIds = lastSeenJson != null
        ? Set<int>.from(jsonDecode(lastSeenJson) as List)
        : <int>{};

    final currentIds = <int>{};
    int newCount = 0;

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;

      final id = item['id'] as int?;
      if (id == null) continue;

      currentIds.add(id);

      if (!lastSeenIds.contains(id)) {
        final title = item['notification']?['title'] as String? ??
            item['title'] as String? ??
            'New Notification';
        final body = item['notification']?['body'] as String? ??
            item['body'] as String? ??
            '';

        await showNotification(
          id: id,
          title: title,
          body: body,
          payload: jsonEncode({'notification_id': id}),
        );
        newCount++;
      }
    }

    await prefs.setString(_lastSeenIdsKey, jsonEncode(currentIds.toList()));

    stdout.writeln('[FallbackPoll] Polled ${data.length} notifications, $newCount new.');
  } catch (e) {
    stdout.writeln('[FallbackPoll] Error: $e');
  }
}

/// Background notification service manager using Firebase Cloud Messaging
class BackgroundNotificationService {
  static bool _initialized = false;

  /// Initialize Firebase and notifications
  static Future<void> initialize() async {
    if (_initialized) return;
    await initializeNotifications();
    _initialized = true;
  }

  /// Start polling (FCM handles real-time, this is a fallback)
  static Future<void> startPolling() async {
    if (!_initialized) await initialize();
    // FCM automatically handles background messages
    // Fallback poll for immediate check
    await _pollAndNotify();
  }

  /// Stop polling (not needed for FCM, but kept for API consistency)
  static Future<void> stopPolling() async {
    // FCM doesn't need to be stopped
  }

  /// Trigger a one-time immediate poll (for testing)
  static Future<void> pollNow() async {
    if (!_initialized) await initialize();
    await _pollAndNotify();
  }

  /// Clear last seen IDs (e.g., on logout)
  static Future<void> clearLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenIdsKey);
  }
}
