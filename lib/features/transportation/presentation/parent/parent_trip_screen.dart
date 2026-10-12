import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/transportation_api.dart';
import '../../data/transportation_models.dart';
import '../widgets/transport_bus_map.dart';

/// Parent live trip screen for one child — polls the backend every 10s.
/// The parent ONLY ever sees their own child's data (enforced server-side).
class ParentTripScreen extends StatefulWidget {
  const ParentTripScreen({super.key, required this.studentId});

  final int studentId;

  @override
  State<ParentTripScreen> createState() => _ParentTripScreenState();
}

class _ParentTripScreenState extends State<ParentTripScreen> {
  static const _pollInterval = Duration(seconds: 10);

  late final TransportationApi _api;
  Timer? _timer;

  ParentActiveTrip? _trip;
  BusLocation? _location;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = TransportationApi(context.read<SessionController>().api);
    _init();
  }

  Future<void> _init() async {
    await _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh(silent: true));
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final trip = await _api.parentActiveTrip(widget.studentId);
      BusLocation? location;
      if (trip != null && trip.tripId > 0) {
        try {
          location = await _api.busLocation(trip.tripId);
        } catch (_) {
          // Live tracking may be disabled by the school — keep the status view.
        }
      }
      if (mounted) {
        setState(() {
          _trip = trip;
          _location = location;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return Scaffold(
      appBar: AppBar(title: const Text('حافلة طفلي')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && trip == null
              ? _ErrorState(message: _error!, onRetry: () => _refresh())
              : trip == null
                  ? const _NoActiveTrip()
                  : RefreshIndicator(
                      onRefresh: () => _refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _StatusCard(trip: trip, location: _location),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _location?.lat != null
                                ? TransportBusMap(
                                    busLat: _location!.lat,
                                    busLng: _location!.lng,
                                    childLat: trip.pickupLat ?? trip.dropoffLat,
                                    childLng: trip.pickupLng ?? trip.dropoffLng,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Text('الخريطة المباشرة متاحة عند بدء الرحلة',
                                          style: TextStyle(color: AppTheme.muted)),
                                    ),
                                  ),
                          ),
                          if (_location?.lat != null && _location?.updatedAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'آخر تحديث للموقع: ${_formatTime(_location!.updatedAt!)}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                              ),
                            ),
                          const SizedBox(height: 20),
                          _TimelineCard(trip: trip),
                          const SizedBox(height: 20),
                          _InfoCard(trip: trip),
                        ],
                      ),
                    ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.trip, required this.location});

  final ParentActiveTrip trip;
  final BusLocation? location;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (trip.status) {
      'EMERGENCY' => ('إنذار طوارئ — تواصل مع المدرسة فوراً', AppTheme.coral, Icons.warning_rounded),
      'NOT_STARTED' => ('الرحلة لم تبدأ بعد', AppTheme.muted, Icons.schedule_rounded),
      'CANCELLED' => ('أُلغيت الرحلة', AppTheme.honey, Icons.cancel_rounded),
      'COMPLETED' => ('اكتملت الرحلة', AppTheme.mint, Icons.check_circle_rounded),
      'APPROACHING' => ('الحافلة تقترب من موقع الاستلام', AppTheme.primary, Icons.near_me_rounded),
      'PICKED_UP' => ('طفلك على الحافلة الآن', AppTheme.primary, Icons.directions_bus_rounded),
      'APPROACHING_DROPOFF' => ('الحافلة تقترب من موقع التوصيل', AppTheme.primary, Icons.near_me_rounded),
      'DROPPED_OFF' => ('تم توصيل طفلك بنجاح', AppTheme.mint, Icons.home_rounded),
      _ => ('الحافلة في الطريق إليك', AppTheme.primary, Icons.directions_bus_rounded),
    };

    final distance = location?.distanceToMyStopM;
    final eta = location?.etaMinutes;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          if (distance != null && trip.status != 'DROPPED_OFF' && trip.status != 'COMPLETED') ...[
            const SizedBox(height: 8),
            Text(
              [
                distance < 1000 ? '${distance.round()} متر' : '${(distance / 1000).toStringAsFixed(1)} كم',
                if (eta != null && eta > 0) 'تقديرياً ${eta.round()} دقيقة',
              ].join('  •  '),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.trip});

  final ParentActiveTrip trip;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('بدء الرحلة', trip.startedAt != null, trip.startedAt),
      ('الحافلة تقترب (استلام)', trip.status == 'APPROACHING' || trip.pickedUpAt != null, null),
      ('طفلك ركب الحافلة', trip.pickedUpAt != null, trip.pickedUpAt),
      ('الحافلة تقترب (توصيل)', trip.status == 'APPROACHING_DROPOFF' || trip.droppedOffAt != null, null),
      ('تم التوصيل', trip.droppedOffAt != null, trip.droppedOffAt),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تسلسل الرحلة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final (label, done, time) = entry.value;
              final isLast = index == steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        done ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                        color: done ? AppTheme.mint : AppTheme.mutedLight,
                        size: 20,
                      ),
                      if (!isLast)
                        Container(width: 2, height: 22, color: done ? AppTheme.mint : AppTheme.mutedLight),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: TextStyle(color: done ? AppTheme.ink : AppTheme.muted)),
                          if (time != null)
                            Text(
                              DateTime.tryParse(time)?.toLocal().toString().substring(11, 16) ?? '',
                              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.trip});

  final ParentActiveTrip trip;

  @override
  Widget build(BuildContext context) {
    final isMorning = trip.direction == 'HOME_TO_SCHOOL';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تفاصيل الرحلة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(Icons.route_rounded, 'الخط', trip.routeName ?? '-'),
            _row(Icons.directions_bus_rounded, 'الحافلة', trip.busNumber ?? '-'),
            _row(Icons.badge_rounded, 'السائق', trip.driverName ?? '-'),
            _row(isMorning ? Icons.wb_twilight_rounded : Icons.wb_sunny_rounded,
                'الاتجاه', isMorning ? 'منزل ← مدرسة (صباحاً)' : 'مدرسة ← منزل (مساءً)'),
            _row(Icons.schedule_rounded, 'الانطلاق المجدول', trip.scheduledStartTime ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.muted),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NoActiveTrip extends StatelessWidget {
  const _NoActiveTrip();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nightlight_rounded, size: 56, color: AppTheme.mutedLight),
            SizedBox(height: 12),
            Text('لا توجد رحلة نشطة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('ستظهر حافلة طفلك هنا فور بدء رحلتها',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
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
            const Text('تعذر الاتصال بالخادم'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
