import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../data/transportation_api.dart';
import '../../data/transportation_models.dart';

/// Simple upcoming-trips schedule for the driver.
class DriverScheduleContent extends StatefulWidget {
  const DriverScheduleContent({super.key});

  @override
  State<DriverScheduleContent> createState() => _DriverScheduleContentState();
}

class _DriverScheduleContentState extends State<DriverScheduleContent> {
  List<DriverTrip> _trips = [];
  bool _loading = true;
  String? _error;

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
      final trips = await api.driverToday();
      if (mounted) {
        setState(() {
          _trips = trips;
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

  @override
  Widget build(BuildContext context) {
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
                    Text('تعذر التحميل: $_error', style: const TextStyle(color: AppTheme.coral)),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
            ),
          if (!_loading && _error == null && _trips.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('لا توجد رحلات مجدولة')),
              ),
            ),
          ..._trips.map((trip) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    trip.direction == 'HOME_TO_SCHOOL'
                        ? Icons.wb_twilight_rounded
                        : Icons.wb_sunny_rounded,
                    color: AppTheme.primary,
                  ),
                  title: Text(trip.route?.name ?? 'خط'),
                  subtitle: Text(
                    '${trip.direction == 'HOME_TO_SCHOOL' ? 'صباحاً' : 'مساءً'} — ${trip.scheduledStartTime ?? '-'} — ${trip.bus?.busNumber ?? ''}',
                  ),
                  trailing: Text(
                    switch (trip.status) {
                      'SCHEDULED' => 'مجدولة',
                      'READY' => 'جاهزة',
                      'IN_PROGRESS' => 'جارية',
                      'EMERGENCY' => 'طوارئ',
                      'COMPLETED' => 'مكتملة',
                      'CANCELLED' => 'ملغاة',
                      _ => trip.status,
                    },
                    style: TextStyle(
                      color: trip.isActive ? AppTheme.mint : AppTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
