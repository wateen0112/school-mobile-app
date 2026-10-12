import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../data/transportation_api.dart';
import '../../data/transportation_models.dart';
import '../../services/driver_gps_service.dart';

/// Driver home — extremely simple: today's assigned trips + one-tap start.
class DriverHomeContent extends StatefulWidget {
  const DriverHomeContent({super.key});

  @override
  State<DriverHomeContent> createState() => _DriverHomeContentState();
}

class _DriverHomeContentState extends State<DriverHomeContent> {
  DriverHome? _home;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = TransportationApi(context.read<SessionController>().api);
      final home = await api.driverHome();
      if (mounted) {
        setState(() {
          _home = home;
          _loading = false;
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

  Future<void> _startTrip(DriverTrip trip) async {
    // Explain why location is needed before requesting permission (§42).
    final granted = await DriverGpsService.ensurePermission();
    if (!mounted) return;
    if (!granted) {
      await _showPermissionDialog();
      return;
    }

    try {
      final api = TransportationApi(context.read<SessionController>().api);
      final started = await api.startTrip(trip.id);
      if (!mounted) return;
      context.push('/driver/active-trip', extra: started.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر بدء الرحلة: $e')),
        );
      }
    }
  }

  Future<void> _showPermissionDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صلاحية الموقع مطلوبة'),
        content: const Text(
          'نحتاج إلى صلاحية الموقع لمتابعة موقع الحافلة وإخطار أولياء الأمور أثناء الرحلة. يرجى تفعيلها من إعدادات الجهاز.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقاً')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = _home;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
        children: [
          if (_loading) const LoadingShimmer(),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('تعذر تحميل البيانات: $_error',
                        style: const TextStyle(color: AppTheme.coral)),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
            ),
          if (home != null) ...[
            _HeaderCard(home: home),
            const SizedBox(height: 16),
            Text('رحلات اليوم', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (home.todayTrips.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('لا توجد رحلات مجدولة لك اليوم')),
                ),
              ),
            ...home.todayTrips.map((trip) => _TripCard(
                  trip: trip,
                  isActive: trip.id == home.activeTripId,
                  onStart: () => _startTrip(trip),
                  onContinue: () => context.push('/driver/active-trip', extra: trip.id),
                )),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.home});

  final DriverHome home;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.primaryPale,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحباً، ${home.driverName}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    home.assignedBus != null
                        ? 'حافلتك: ${home.assignedBus!.busNumber}${home.assignedBus!.name != null ? ' — ${home.assignedBus!.name}' : ''}'
                        : 'لم تُسند لك حافلة بعد',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.isActive,
    required this.onStart,
    required this.onContinue,
  });

  final DriverTrip trip;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isMorning = trip.direction == 'HOME_TO_SCHOOL';
    final statusLabel = switch (trip.status) {
      'SCHEDULED' => 'مجدولة',
      'READY' => 'جاهزة',
      'IN_PROGRESS' => 'جارية الآن',
      'EMERGENCY' => 'طوارئ!',
      'COMPLETED' => 'مكتملة',
      'CANCELLED' => 'ملغاة',
      _ => trip.status,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isActive
            ? const BorderSide(color: AppTheme.mint, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isMorning ? Icons.wb_twilight_rounded : Icons.wb_sunny_rounded,
                    color: isMorning ? AppTheme.primary : AppTheme.honey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.route?.name ?? 'خط',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.mint.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppTheme.mint : AppTheme.muted,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Builder(builder: (_) {
              final directionLabel =
                  isMorning ? 'منزل ← مدرسة (صباحاً)' : 'مدرسة ← منزل (مساءً)';
              return Text(
                '$directionLabel  •  ${trip.bus?.busNumber ?? ''}  •  البدء: ${trip.scheduledStartTime ?? '-'}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              );
            }),
            const SizedBox(height: 14),
            if (trip.isActive || isActive)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.near_me_rounded),
                  label: const Text('متابعة الرحلة الجارية', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.mint,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else if (trip.canStart)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text('بدء الرحلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
