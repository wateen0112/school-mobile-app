import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/transportation_api.dart';
import 'driver_location_foreground_service.dart';
import 'gps_queue_store.dart';

/// Coordinates GPS tracking for an active driver trip.
///
/// Responsibilities:
///  - Explain-then-request location permission helpers (§42).
///  - Keep a lightweight in-app position stream for live UI state.
///  - On Android, hand the heavy lifting (periodic POSTing + offline
///    queue + persistent notification) to the location-typed foreground
///    service so tracking continues while the app is backgrounded.
///  - On iOS (no always-on foreground service), fall back to an in-app
///    timer that posts while the app is alive.
///
/// The offline queue lives in [GpsQueueStore] and is shared with the
/// foreground-service isolate, so points captured in the background are
/// flushed by whichever side succeeds first — no duplicates (points are
/// time-stamped; pickup/dropoff events use client_event_id).
class DriverGpsService extends ChangeNotifier {
  DriverGpsService(this._api);

  final TransportationApi _api;

  StreamSubscription<Position>? _positionSub;
  Timer? _fallbackTimer;
  Position? _latest;
  int? _activeTripId;
  int _intervalSeconds = 10;
  int _fallbackQueueCount = 0;

  bool get isTracking => _activeTripId != null;
  int? get activeTripId => _activeTripId;
  bool get hasQueuedPoints => _fallbackQueueCount > 0;
  int get queuedCount => _fallbackQueueCount;

  /// Explain-then-request location permission flow.
  /// Returns true when tracking is possible.
  static Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> permissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Resume tracking for [tripId] if the persisted handle says it should be
  /// active but no isolate is running (e.g. after an app restart mid-trip).
  static Future<void> resumeIfNeeded(int tripId, TransportationApi api) async {
    final persisted = await ActiveTripStore.tripId();
    if (persisted == null || persisted != tripId) return;
    final service = DriverGpsService(api);
    await service.start(tripId, intervalSeconds: await ActiveTripStore.intervalSeconds());
  }

  Future<void> start(int tripId, {int intervalSeconds = 10}) async {
    if (_activeTripId == tripId) return;
    await stop();

    _activeTripId = tripId;
    _intervalSeconds = intervalSeconds.clamp(3, 120);
    _fallbackQueueCount = (await GpsQueueStore.load()).length;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters — ignore micro-movements
      ),
    ).listen((position) {
      _latest = position;
    });

    // Persist the handle so the foreground service (and future app starts)
    // knows a trip is active.
    await DriverLocationForegroundService.start(
      tripId: tripId,
      intervalSeconds: _intervalSeconds,
    );

    // iOS fallback: no always-on foreground service — post in-app while alive.
    if (!Platform.isAndroid) {
      await _sendPoint();
      _fallbackTimer = Timer.periodic(Duration(seconds: _intervalSeconds), (_) {
        _sendPoint();
      });
    }

    notifyListeners();
  }

  Future<void> stop() async {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;
    _activeTripId = null;
    _latest = null;
    await DriverLocationForegroundService.stop();
    notifyListeners();
  }

  Future<Position?> currentPosition() async {
    if (_latest != null) return _latest;
    try {
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------- iOS fallback

  Future<void> _sendPoint() async {
    final tripId = _activeTripId;
    if (tripId == null) return;

    final position = await currentPosition();
    if (position == null) return;

    final sent = await _api.sendLocation(
      tripId,
      latitude: position.latitude,
      longitude: position.longitude,
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
      _syncQueueCount();
      return;
    }

    // Flush queued points oldest-first (no duplicates — time-stamped points).
    final queue = await GpsQueueStore.load();
    var flushed = 0;
    for (final point in queue) {
      final ok = await _api.sendLocation(
        tripId,
        latitude: point.lat,
        longitude: point.lng,
        accuracy: point.accuracy,
        speed: point.speed,
        heading: point.heading,
      );
      if (!ok) break; // keep order; retry the rest next cycle
      flushed++;
    }
    if (flushed > 0) {
      await GpsQueueStore.dropOldest(flushed);
      _syncQueueCount();
    }
  }

  Future<void> _syncQueueCount() async {
    _fallbackQueueCount = (await GpsQueueStore.load()).length;
    notifyListeners();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}
