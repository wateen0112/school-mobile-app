import '../../../core/network/api_service.dart';
import 'transportation_models.dart';

/// Transportation API — driver and parent mobile endpoints.
class TransportationApi {
  TransportationApi(this._api);

  final ApiService _api;

  Map<String, dynamic> _data(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map) return data.cast<String, dynamic>();
    if (data is List) return {'items': data};
    return body;
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is List) return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    return const [];
  }

  // ------------------------------------------------------------- driver

  Future<DriverHome> driverHome() async =>
      DriverHome.fromJson(_data(await _api.get('/driver/home')));

  Future<List<DriverTrip>> driverToday() async => _list(await _api.get('/driver/trips/today'))
      .map(DriverTrip.fromJson)
      .toList();

  Future<DriverTrip> driverTrip(int id) async =>
      DriverTrip.fromJson(_data(await _api.get('/driver/trips/$id')));

  Future<DriverTrip> startTrip(int id) async =>
      DriverTrip.fromJson(_data(await _api.post('/driver/trips/$id/start')));

  Future<DriverTrip> endTrip(int id) async =>
      DriverTrip.fromJson(_data(await _api.post('/driver/trips/$id/end')));

  Future<DriverTrip> cancelTrip(int id, {String? reason}) async =>
      DriverTrip.fromJson(_data(await _api.post('/driver/trips/$id/cancel', data: {
        if (reason != null) 'reason': reason,
      })));

  /// One GPS update. Returns false (without throwing) when the server
  /// rejects the point so the caller can keep the trip alive locally.
  Future<bool> sendLocation(
    int tripId, {
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    try {
      await _api.post('/driver/trips/$tripId/location', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } on ApiFailure {
      return false;
    }
  }

  Future<NextStop> nextStop(int tripId) async =>
      NextStop.fromJson(_data(await _api.get('/driver/trips/$tripId/next-stop')));

  Future<Map<String, dynamic>> pickedUp(
    int tripId,
    int tripStudentId, {
    required String clientEventId,
    double? lat,
    double? lng,
  }) async =>
      _data(await _api.post(
        '/driver/trips/$tripId/students/$tripStudentId/picked-up',
        data: {
          'client_event_id': clientEventId,
          if (lat != null) 'latitude': lat,
          if (lng != null) 'longitude': lng,
        },
      ));

  Future<Map<String, dynamic>> droppedOff(
    int tripId,
    int tripStudentId, {
    required String clientEventId,
    double? lat,
    double? lng,
  }) async =>
      _data(await _api.post(
        '/driver/trips/$tripId/students/$tripStudentId/dropped-off',
        data: {
          'client_event_id': clientEventId,
          if (lat != null) 'latitude': lat,
          if (lng != null) 'longitude': lng,
        },
      ));

  Future<DriverTrip> emergency(
    int tripId, {
    double? lat,
    double? lng,
  }) async =>
      DriverTrip.fromJson(_data(await _api.post('/driver/trips/$tripId/emergency', data: {
        'confirmed': true,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      })));

  // ------------------------------------------------------------- parent

  Future<List<ParentChildTransport>> parentChildren() async =>
      _list(await _api.get('/parent/transportation/children'))
          .map(ParentChildTransport.fromJson)
          .toList();

  Future<ParentActiveTrip?> parentActiveTrip(int studentId) async {
    final data = _data(
      await _api.get('/parent/transportation/children/$studentId/active-trip'),
    );
    if (data['trip'] == null &&
        (data['status'] == 'NOT_STARTED' || data['status'] == null)) {
      return null;
    }
    return ParentActiveTrip.fromJson(data);
  }

  Future<BusLocation> busLocation(int tripId) async =>
      BusLocation.fromJson(_data(await _api.get('/parent/transportation/trips/$tripId/bus-location')));
}
