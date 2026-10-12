import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A GPS point captured while offline.
class QueuedGpsPoint {
  const QueuedGpsPoint({
    required this.lat,
    required this.lng,
    this.accuracy,
    this.speed,
    this.heading,
    required this.recordedAt,
  });

  final double lat;
  final double lng;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final String recordedAt;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        'recorded_at': recordedAt,
      };

  factory QueuedGpsPoint.fromJson(Map<String, dynamic> json) => QueuedGpsPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        recordedAt: '${json['recorded_at']}',
      );
}

/// On-device storage for GPS points that failed to send.
///
/// Shared between the app isolate (DriverGpsService) and the headless
/// foreground-service isolate (DriverLocationForegroundService) through
/// SharedPreferences so offline points never duplicate or get lost when
/// the app moves between foreground and background.
class GpsQueueStore {
  GpsQueueStore._();

  static const _queueKey = 'transportation.gps_queue';
  static const _maxPoints = 500;

  static Future<List<QueuedGpsPoint>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => QueuedGpsPoint.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<QueuedGpsPoint> points) async {
    final prefs = await SharedPreferences.getInstance();
    if (points.isEmpty) {
      await prefs.remove(_queueKey);
      return;
    }
    final trimmed = points.length > _maxPoints
        ? points.sublist(points.length - _maxPoints)
        : points;
    await prefs.setString(
      _queueKey,
      jsonEncode(trimmed.map((p) => p.toJson()).toList()),
    );
  }

  static Future<void> enqueue(QueuedGpsPoint point) async {
    final points = await load();
    points.add(point);
    await save(points);
  }

  /// Remove the oldest [count] points (they were acknowledged by server).
  static Future<void> dropOldest(int count) async {
    if (count <= 0) return;
    final points = await load();
    if (points.isEmpty) return;
    final remaining = points.length <= count ? <QueuedGpsPoint>[] : points.sublist(count);
    await save(remaining);
  }
}

/// Persisted handle for the currently tracked trip so the foreground
/// service can resume after process death / app restart.
class ActiveTripStore {
  ActiveTripStore._();

  static const _tripIdKey = 'transportation.active_trip_id';
  static const _intervalKey = 'transportation.gps_interval_s';

  static Future<void> save({required int tripId, required int intervalSeconds}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tripIdKey, tripId);
    await prefs.setInt(_intervalKey, intervalSeconds);
  }

  static Future<int?> tripId() async =>
      (await SharedPreferences.getInstance()).getInt(_tripIdKey);

  static Future<int> intervalSeconds() async =>
      (await SharedPreferences.getInstance()).getInt(_intervalKey) ?? 10;

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tripIdKey);
    await prefs.remove(_intervalKey);
  }
}
