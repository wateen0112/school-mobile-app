import 'dart:convert';

/// Transportation models — thin fromJson wrappers matching the backend
/// /driver/* and /parent/transportation/* API shapes.

class DriverHome {
  const DriverHome({
    required this.driverName,
    this.employeeNo,
    this.assignedBus,
    required this.todayTrips,
    this.activeTripId,
  });

  final String driverName;
  final String? employeeNo;
  final DriverBus? assignedBus;
  final List<DriverTrip> todayTrips;
  final int? activeTripId;

  factory DriverHome.fromJson(Map<String, dynamic> json) {
    final driver = (json['driver'] as Map?)?.cast<String, dynamic>() ?? {};
    final bus = (json['assigned_bus'] as Map?)?.cast<String, dynamic>();
    final trips = (json['today_trips'] as List? ?? [])
        .map((e) => DriverTrip.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final active = json['active_trip'];
    return DriverHome(
      driverName: '${driver['name'] ?? ''}',
      employeeNo: driver['employee_no'] as String?,
      assignedBus: bus == null ? null : DriverBus.fromJson(bus),
      todayTrips: trips,
      activeTripId: active is int ? active : int.tryParse('$active'),
    );
  }
}

class DriverBus {
  const DriverBus({required this.id, required this.busNumber, this.name});

  final int id;
  final String busNumber;
  final String? name;

  factory DriverBus.fromJson(Map<String, dynamic> json) => DriverBus(
        id: json['id'] as int? ?? 0,
        busNumber: '${json['bus_number'] ?? ''}',
        name: json['name'] as String?,
      );
}

class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.status,
    required this.direction,
    required this.tripDate,
    this.scheduledStartTime,
    this.startedAt,
    this.route,
    this.bus,
    this.gpsIntervalSeconds = 10,
    this.students = const [],
  });

  final int id;
  final String status; // SCHEDULED, READY, IN_PROGRESS, EMERGENCY, COMPLETED, CANCELLED
  final String direction; // HOME_TO_SCHOOL | SCHOOL_TO_HOME
  final String tripDate;
  final String? scheduledStartTime;
  final String? startedAt;
  final DriverRouteInfo? route;
  final DriverBus? bus;
  final int gpsIntervalSeconds;
  final List<DriverTripStudent> students;

  bool get isActive => status == 'IN_PROGRESS' || status == 'EMERGENCY';
  bool get canStart => status == 'SCHEDULED' || status == 'READY';

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    final route = (json['route'] as Map?)?.cast<String, dynamic>();
    final bus = (json['bus'] as Map?)?.cast<String, dynamic>();
    return DriverTrip(
      id: json['id'] as int? ?? 0,
      status: '${json['status'] ?? 'SCHEDULED'}',
      direction: '${json['direction'] ?? 'HOME_TO_SCHOOL'}',
      tripDate: '${json['trip_date'] ?? ''}',
      scheduledStartTime: json['scheduled_start_time'] as String?,
      startedAt: json['started_at'] as String?,
      route: route == null ? null : DriverRouteInfo.fromJson(route),
      bus: bus == null ? null : DriverBus.fromJson(bus),
      gpsIntervalSeconds:
          (json['gps_interval_s'] as num?)?.toInt() ?? 10,
      students: (json['students'] as List? ?? [])
          .map((e) => DriverTripStudent.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class DriverRouteInfo {
  const DriverRouteInfo({required this.id, required this.name, this.direction});

  final int id;
  final String name;
  final String? direction;

  factory DriverRouteInfo.fromJson(Map<String, dynamic> json) =>
      DriverRouteInfo(
        id: json['id'] as int? ?? 0,
        name: '${json['name'] ?? ''}',
        direction: json['direction'] as String?,
      );
}

class DriverTripStudent {
  const DriverTripStudent({
    required this.tripStudentId,
    required this.studentId,
    required this.name,
    required this.stopOrder,
    required this.status,
    this.pickupLat,
    this.pickupLng,
    this.pickupAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffAddress,
  });

  final int tripStudentId;
  final int studentId;
  final String name;
  final int stopOrder;
  final String status;
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffAddress;

  factory DriverTripStudent.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    String name = '${json['name'] ?? ''}';
    // Backend returns Spatie translatable names as {"ar":..,"en":..}
    if (name.startsWith('{')) {
      try {
        // fall back handled by caller display helper
      } catch (_) {}
    }
    return DriverTripStudent(
      tripStudentId: json['trip_student_id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      name: name,
      stopOrder: (json['stop_order'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? 'WAITING'}',
      pickupLat: d(json['pickup']?['lat']),
      pickupLng: d(json['pickup']?['lng']),
      pickupAddress: json['pickup']?['address'] as String?,
      dropoffLat: d(json['dropoff']?['lat']),
      dropoffLng: d(json['dropoff']?['lng']),
      dropoffAddress: json['dropoff']?['address'] as String?,
    );
  }
}

class NextStop {
  const NextStop({
    required this.tripStudentId,
    required this.studentName,
    required this.stopOrder,
    required this.status,
    required this.stopKind,
    this.address,
    this.lat,
    this.lng,
    this.distanceMeters,
    this.etaMinutes,
    required this.remaining,
  });

  final int tripStudentId;
  final String studentName;
  final int stopOrder;
  final String status;
  final String? stopKind; // pickup | dropoff
  final String? address;
  final double? lat;
  final double? lng;
  final double? distanceMeters;
  final double? etaMinutes;
  final int remaining;

  factory NextStop.fromJson(Map<String, dynamic> json) {
    final next = (json['next'] as Map?)?.cast<String, dynamic>();
    if (next == null) {
      return const NextStop(
        tripStudentId: 0,
        studentName: '',
        stopOrder: 0,
        status: 'DONE',
        stopKind: null,
        remaining: 0,
      );
    }
    final student = (next['student'] as Map?)?.cast<String, dynamic>();
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    return NextStop(
      tripStudentId: (next['trip_student_id'] as num?)?.toInt() ?? 0,
      studentName: '${student?['name'] ?? ''}',
      stopOrder: (next['stop_order'] as num?)?.toInt() ?? 0,
      status: '${next['status'] ?? 'WAITING'}',
      stopKind: next['stop_kind'] as String?,
      address: next['address'] as String?,
      lat: d(next['lat']),
      lng: d(next['lng']),
      distanceMeters: d(next['distance_m']),
      etaMinutes: d(next['eta_minutes']),
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Parent-side child transportation summary.
class ParentChildTransport {
  const ParentChildTransport({
    required this.studentId,
    required this.name,
    required this.transportationEnabled,
    this.hasMorningRoute = false,
    this.hasAfternoonRoute = false,
    this.activeTrip,
  });

  final int studentId;
  final String name;
  final bool transportationEnabled;
  final bool hasMorningRoute;
  final bool hasAfternoonRoute;
  final ParentActiveTrip? activeTrip;

  factory ParentChildTransport.fromJson(Map<String, dynamic> json) {
    final trip = (json['active_trip'] as Map?)?.cast<String, dynamic>();
    return ParentChildTransport(
      studentId: json['student_id'] as int? ?? 0,
      name: '${json['name'] ?? ''}',
      transportationEnabled: json['transportation_enabled'] == true,
      hasMorningRoute: json['has_morning_route'] == true,
      hasAfternoonRoute: json['has_afternoon_route'] == true,
      activeTrip: trip == null ? null : ParentActiveTrip.fromJson(trip),
    );
  }
}

class ParentActiveTrip {
  const ParentActiveTrip({
    required this.tripId,
    required this.status,
    required this.direction,
    this.scheduledStartTime,
    this.startedAt,
    this.routeName,
    this.busNumber,
    this.driverName,
    this.myChildStatus,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.busLat,
    this.busLng,
    this.busLocationUpdatedAt,
    this.pickedUpAt,
    this.droppedOffAt,
  });

  final int tripId;
  final String status;
  final String direction;
  final String? scheduledStartTime;
  final String? startedAt;
  final String? routeName;
  final String? busNumber;
  final String? driverName;
  final String? myChildStatus;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? busLat;
  final double? busLng;
  final String? busLocationUpdatedAt;
  final String? pickedUpAt;
  final String? droppedOffAt;

  factory ParentActiveTrip.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    final route = (json['route'] as Map?)?.cast<String, dynamic>();
    final bus = (json['bus'] as Map?)?.cast<String, dynamic>();
    final mine = (json['my_child'] as Map?)?.cast<String, dynamic>();
    final loc = (json['bus_location'] as Map?)?.cast<String, dynamic>();
    return ParentActiveTrip(
      tripId: json['trip_id'] as int? ?? 0,
      status: '${json['status'] ?? 'NOT_STARTED'}',
      direction: '${json['direction'] ?? 'HOME_TO_SCHOOL'}',
      scheduledStartTime: json['scheduled_start_time'] as String?,
      startedAt: json['started_at'] as String?,
      routeName: route?['name'] as String?,
      busNumber: bus?['bus_number'] as String?,
      driverName: json['driver_name'] as String?,
      myChildStatus: mine?['status'] as String?,
      pickupLat: d(mine?['pickup']?['lat']),
      pickupLng: d(mine?['pickup']?['lng']),
      dropoffLat: d(mine?['dropoff']?['lat']),
      dropoffLng: d(mine?['dropoff']?['lng']),
      busLat: d(loc?['lat']),
      busLng: d(loc?['lng']),
      busLocationUpdatedAt: loc?['recorded_at'] as String?,
      pickedUpAt: mine?['picked_up_at'] as String?,
      droppedOffAt: mine?['dropped_off_at'] as String?,
    );
  }
}

class BusLocation {
  const BusLocation({
    required this.tripId,
    required this.status,
    this.lat,
    this.lng,
    this.updatedAt,
    this.distanceToMyStopM,
    this.etaMinutes,
  });

  final int tripId;
  final String status;
  final double? lat;
  final double? lng;
  final String? updatedAt;
  final double? distanceToMyStopM;
  final double? etaMinutes;

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    final loc = (json['location'] as Map?)?.cast<String, dynamic>();
    return BusLocation(
      tripId: json['trip_id'] as int? ?? 0,
      status: '${json['status'] ?? ''}',
      lat: d(loc?['lat']),
      lng: d(loc?['lng']),
      updatedAt: loc?['recorded_at'] as String?,
      distanceToMyStopM: d(json['distance_to_my_stop_m']),
      etaMinutes: d(json['eta_minutes']),
    );
  }
}

/// Backend returns Spatie translatable fields as {"ar":..,"en":..}; this
/// picks the best display value for a raw decoded dynamic.
String transportDisplayName(dynamic raw, {bool preferAr = true}) {
  if (raw == null) return '';
  Map<String, dynamic>? map;
  if (raw is Map) {
    map = raw.cast<String, dynamic>();
  } else if (raw is String && raw.startsWith('{')) {
    try {
      map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return raw;
    }
  } else {
    return '$raw';
  }
  final ar = '${map['ar'] ?? ''}';
  final en = '${map['en'] ?? ''}';
  if (preferAr) return ar.isNotEmpty ? ar : en;
  return en.isNotEmpty ? en : ar;
}
