import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';
import 'gps_queue_store.dart';

/// Foreground-service GPS tracking for an active driver trip (Android).
///
/// Why this exists: drivers background the app for the whole trip. A plain
/// in-app Timer stops when the OS freezes the activity, breaking tracking
/// and — worse — the parent/admin live view. A `location`-typed foreground
/// service keeps posting GPS updates with a persistent notification while
/// the trip is active, and survives process death (it re-reads the trip
/// handle from SharedPreferences on start).
///
/// iOS has no equivalent always-on foreground service; there the in-app
/// timer path (DriverGpsService fallback) continues to be used.
///
/// Must be initialized once in `main()` before `runApp`.
@pragma('vm:entry-point')
class DriverLocationForegroundService {
  DriverLocationForegroundService._();

  static const _channelId = 'driver_location_service';
  static const _notificationId = 4477;

  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'المواصلات المدرسية',
        initialNotificationContent: 'جارٍ تجهيز تتبع الرحلة…',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
    _initialized = true;
  }

  /// iOS background-fetch entry — real tracking on iOS runs in-app; this
  /// just keeps the plugin contract satisfied.
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async => true;

  /// Headless entry-point: runs in the service isolate, independent of the
  /// UI. Never call directly.
  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    final prefs = await SharedPreferences.getInstance();

    final tripId = prefs.getInt('transportation.active_trip_id');
    final token = prefs.getString('auth.token');
    if (tripId == null || token == null || token.isEmpty) {
      service.stopSelf();
      return;
    }

    final interval = (prefs.getInt('transportation.gps_interval_s') ?? 10).clamp(3, 120);

    // This isolate cannot reach ErrorLocale (static per isolate), so read the
    // same 'locale' preference SessionController persists.
    final savedLocale = prefs.getString('locale') ?? 'ar';
    final lang = savedLocale == 'ar' ? 'ar' : 'en';

    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'lang': lang,
        'X-Locale': lang,
        'Accept-Language': lang == 'ar' ? 'ar' : 'en-US,en;q=0.9',
      },
    ));

    Timer? timer;

    Future<void> updateNotification(String content) async {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'رحلة نشطة — تتبع الموقع',
          content: content,
        );
      }
    }

    Future<bool> postPoint(double lat, double lng,
        {double? accuracy, double? speed, double? heading}) async {
      try {
        await dio.post('/driver/trips/$tripId/location', data: {
          'latitude': lat,
          'longitude': lng,
          if (accuracy != null) 'accuracy': accuracy,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
          'recorded_at': DateTime.now().toUtc().toIso8601String(),
        });
        return true;
      } on DioException {
        return false;
      }
    }

    Future<void> tick() async {
      // Trip ended from the UI while the service was running?
      final currentTripId =
          (await SharedPreferences.getInstance()).getInt('transportation.active_trip_id');
      if (currentTripId == null || currentTripId != tripId) {
        timer?.cancel();
        service.stopSelf();
        return;
      }

      // Permission can be revoked while the service runs — degrade loudly.
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        await updateNotification('صلاحية الموقع مطلوبة — افتح التطبيق لإعادة تفعيلها');
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (_) {
        await updateNotification('تعذر الحصول على الموقع — سيحاول النظام مجدداً');
        return;
      }

      final sent = await postPoint(
        position.latitude,
        position.longitude,
        accuracy: position.accuracy,
        speed: position.speed >= 0 ? position.speed : null,
        heading: position.heading >= 0 ? position.heading : null,
      );

      if (!sent) {
        await GpsQueueStore.enqueue(QueuedGpsPoint(
          lat: position.latitude,
          lng: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed >= 0 ? position.speed : null,
          heading: position.heading >= 0 ? position.heading : null,
          recordedAt: DateTime.now().toUtc().toIso8601String(),
        ));
        final queued = await GpsQueueStore.load();
        await updateNotification('لا يوجد اتصال — ${queued.length} نقطة بالانتظار');
        return;
      }

      // Flush the offline queue oldest-first after a successful send.
      final queue = await GpsQueueStore.load();
      var flushed = 0;
      for (final point in queue) {
        final ok = await postPoint(point.lat, point.lng,
            accuracy: point.accuracy, speed: point.speed, heading: point.heading);
        if (!ok) break; // keep order; the rest retry next cycle
        flushed++;
      }
      if (flushed > 0) await GpsQueueStore.dropOldest(flushed);

      final time = '${DateTime.now().hour.toString().padLeft(2, '0')}:'
          '${DateTime.now().minute.toString().padLeft(2, '0')}:'
          '${DateTime.now().second.toString().padLeft(2, '0')}';
      await updateNotification('آخر تحديث $time');
    }

    await updateNotification('بدأ تتبع الرحلة');
    await tick();
    timer = Timer.periodic(Duration(seconds: interval), (_) => tick());

    service.on('stop').listen((_) {
      timer?.cancel();
      service.stopSelf();
    });
  }

  // ------------------------------------------------------------ controls

  static Future<bool> isRunning() async => _service.isRunning();

  /// Start (or restart) foreground tracking for [tripId].
  static Future<void> start({required int tripId, required int intervalSeconds}) async {
    await initialize();
    await ActiveTripStore.save(tripId: tripId, intervalSeconds: intervalSeconds);
    if (!Platform.isAndroid) return; // iOS handled by the in-app fallback
    if (await _service.isRunning()) {
      // Restart so the isolate picks up the latest trip/interval handle.
      _service.invoke('stop');
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _service.startService();
  }

  /// Stop tracking: clears the persisted trip handle (the running isolate
  /// observes this on its next tick and calls stopSelf) and sends an
  /// immediate 'stop' event for the same- isolate listener.
  static Future<void> stop() async {
    await ActiveTripStore.clear();
    if (!Platform.isAndroid) return;
    _service.invoke('stop');
  }
}
