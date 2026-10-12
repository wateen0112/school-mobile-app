import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/transportation_api.dart';
import '../../data/transportation_models.dart';
import '../../services/driver_gps_service.dart';
import '../../services/driver_location_foreground_service.dart';
import '../../services/gps_queue_store.dart';

/// Active trip screen for the driver.
///
/// Deliberately minimal (§34): one giant action button for the current
/// stop, a short roster, and a protected emergency button. The driver may
/// be operating a vehicle — no complicated navigation.
class DriverTripScreen extends StatefulWidget {
  const DriverTripScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  final _uuid = const Uuid();

  late final TransportationApi _api;
  DriverGpsService? _gps;
  Timer? _pollTimer;

  DriverTrip? _trip;
  List<DriverTripStudent> _students = [];
  NextStop? _next;
  bool _loading = true;
  String? _error;
  bool _busy = false;
  bool _gpsWasGranted = false;

  @override
  void initState() {
    super.initState();
    _api = TransportationApi(context.read<SessionController>().api);
    _init();
  }

  Future<void> _init() async {
    _gpsWasGranted = await DriverGpsService.permissionGranted();
    await _refresh();
    // GPS tracking follows the trip lifecycle; only start when active.
    final trip = _trip;
    if (trip != null && trip.isActive && _gpsWasGranted) {
      if (await DriverLocationForegroundService.isRunning() &&
          await ActiveTripStore.tripId() == trip.id) {
        // Tracking already lives in the foreground service (e.g. the screen
        // was re-entered) — attach local state without restarting it.
        _gps ??= DriverGpsService(_api);
      } else {
        await _startGps(trip);
      }
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  Future<void> _startGps(DriverTrip trip) async {
    _gps ??= DriverGpsService(_api);
    await _gps!.start(trip.id, intervalSeconds: trip.gpsIntervalSeconds);
  }

  Future<void> _refresh() async {
    try {
      final trip = await _api.driverTrip(widget.tripId);
      NextStop? next;
      try {
        next = await _api.nextStop(widget.tripId);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _trip = trip;
          _students = trip.students;
          _next = next;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markCurrent(String action) => _runGuarded(() async {
        final next = _next;
        if (next == null || next.tripStudentId == 0) return;
        final position = await _gps?.currentPosition();
        // client_event_id makes retries idempotent on the server.
        final eventId = _uuid.v4();
        if (action == 'picked_up') {
          await _api.pickedUp(
            widget.tripId,
            next.tripStudentId,
            clientEventId: eventId,
            lat: position?.latitude,
            lng: position?.longitude,
          );
        } else {
          await _api.droppedOff(
            widget.tripId,
            next.tripStudentId,
            clientEventId: eventId,
            lat: position?.latitude,
            lng: position?.longitude,
          );
        }
        await _refresh();
      });

  Future<void> _endTrip() => _runGuarded(() async {
        await _gps?.stop();
        await _api.endTrip(widget.tripId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنهاء الرحلة بنجاح')),
          );
          context.pop();
        }
      });

  Future<void> _emergency() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.coral, size: 28),
            SizedBox(width: 8),
            Text('إنذار طوارئ'),
          ],
        ),
        content: const Text('هل أنت متأكد من إرسال إنذار طوارئ؟ سيُخطَر مسؤولو المدرسة وأولياء الأمور فوراً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.coral),
            child: const Text('نعم، أرسل الإنذار'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runGuarded(() async {
      final position = await _gps?.currentPosition();
      await _api.emergency(
        widget.tripId,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      await _refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _gps?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final next = _next;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip == null ? 'الرحلة' : 'الخط: ${trip.route?.name ?? ''}'),
        automaticallyImplyLeading: false,
        actions: [
          if (trip != null && trip.isActive)
            IconButton(
              onPressed: _emergency,
              icon: const Icon(Icons.sos_rounded, color: AppTheme.coral),
              tooltip: 'طوارئ',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && trip == null
              ? _ErrorState(message: _error!, onRetry: _refresh)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (trip != null) _TripStatusBanner(trip: trip, gpsGranted: _gpsWasGranted),
                      const SizedBox(height: 16),
                      if (next != null && next.tripStudentId != 0)
                        _NextStopCard(next: next, busy: _busy, onConfirm: () => _markCurrent(
                              next.status == 'WAITING' ? 'picked_up' : 'dropped_off',
                            ))
                      else if (trip != null && trip.isActive)
                        const _AllDoneCard(),
                      const SizedBox(height: 16),
                      if (trip != null && trip.isActive)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _endTrip,
                            icon: const Icon(Icons.flag_rounded),
                            label: const Text('إنهاء الرحلة', style: TextStyle(fontSize: 16)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.mint,
                              side: const BorderSide(color: AppTheme.mint, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (_students.isNotEmpty) ...[
                        Text('قائمة الطلاب', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ..._students.map((s) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: s.status == 'DROPPED_OFF'
                                    ? AppTheme.mint.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.05),
                                child: Text('${s.stopOrder}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                              ),
                              title: Text(transportDisplayName(s.name)),
                              subtitle: Text(
                                s.status == 'WAITING'
                                    ? 'بانتظار'
                                    : s.status == 'PICKED_UP'
                                        ? 'على الحافلة'
                                        : 'تم التوصيل',
                              ),
                              trailing: Icon(
                                s.status == 'WAITING'
                                    ? Icons.circle_outlined
                                    : s.status == 'PICKED_UP'
                                        ? Icons.directions_bus_rounded
                                        : Icons.check_circle_rounded,
                                color: s.status == 'WAITING'
                                    ? AppTheme.muted
                                    : s.status == 'PICKED_UP'
                                        ? AppTheme.primary
                                        : AppTheme.mint,
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _TripStatusBanner extends StatelessWidget {
  const _TripStatusBanner({required this.trip, required this.gpsGranted});

  final DriverTrip trip;
  final bool gpsGranted;

  @override
  Widget build(BuildContext context) {
    final isEmergency = trip.status == 'EMERGENCY';
    final isMorning = trip.direction == 'HOME_TO_SCHOOL';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEmergency ? AppTheme.coral.withValues(alpha: 0.12) : AppTheme.primaryPale,
        borderRadius: BorderRadius.circular(18),
        border: isEmergency ? Border.all(color: AppTheme.coral) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isEmergency ? Icons.warning_rounded : Icons.directions_bus_rounded,
                  color: isEmergency ? AppTheme.coral : AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEmergency
                      ? 'وضع الطوارئ نشط — ابقَ هادئاً، الإدارة مطلعة'
                      : (isMorning ? 'رحلة الصباح — منزل ← مدرسة' : 'رحلة المساء — مدرسة ← منزل'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isEmergency ? AppTheme.coral : AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'الحافلة: ${trip.bus?.busNumber ?? '-'}  •  البدء: ${trip.scheduledStartTime ?? '-'}',
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          if (!gpsGranted)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.gps_off_rounded, color: AppTheme.coral, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('صلاحية الموقع غير مفعّلة — فعّلها لمتابعة تتبع الحافلة',
                        style: TextStyle(color: AppTheme.coral, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NextStopCard extends StatelessWidget {
  const _NextStopCard({required this.next, required this.busy, required this.onConfirm});

  final NextStop next;
  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isPickup = next.stopKind == 'pickup' || next.status == 'WAITING';
    final distanceText = next.distanceMeters == null
        ? null
        : next.distanceMeters! < 1000
            ? '${next.distanceMeters!.round()} م'
            : '${(next.distanceMeters! / 1000).toStringAsFixed(1)} كم';
    final etaText = next.etaMinutes != null && next.etaMinutes! > 0
        ? '≈ ${next.etaMinutes!.round()} دقيقة'
        : null;

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isPickup ? 'الموقف التالي — استلام' : 'الموقف التالي — توصيل',
              style: const TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              transportDisplayName(next.studentName),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            if (next.address != null && next.address!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Flexible(child: Text(next.address!, style: const TextStyle(color: AppTheme.muted))),
                ],
              ),
            ],
            if (distanceText != null) ...[
              const SizedBox(height: 6),
              Text(
                [distanceText, etaText].whereType<String>().join('  •  '),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'المتبقي: ${next.remaining} موقف',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 72,
              child: FilledButton.icon(
                onPressed: busy ? null : onConfirm,
                icon: busy
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : Icon(isPickup ? Icons.login_rounded : Icons.logout_rounded, size: 32),
                label: Text(
                  isPickup ? 'تم الركوب' : 'تم التوصيل',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isPickup ? AppTheme.primary : AppTheme.mint,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.mint, size: 48),
            SizedBox(height: 8),
            Text('اكتملت جميع المواقف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('اضغط «إنهاء الرحلة» لإكمال الرحلة', style: TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.coral, size: 48),
            const SizedBox(height: 12),
            Text('تعذر الاتصال بالخادم', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
