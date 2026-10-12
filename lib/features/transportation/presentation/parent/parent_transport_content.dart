import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../data/transportation_api.dart';
import '../../data/transportation_models.dart';

/// Parent transportation hub — one card per child with live trip status.
class ParentTransportContent extends StatefulWidget {
  const ParentTransportContent({super.key});

  @override
  State<ParentTransportContent> createState() => _ParentTransportContentState();
}

class _ParentTransportContentState extends State<ParentTransportContent> {
  List<ParentChildTransport> _children = [];
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
      final children = await api.parentChildren();
      if (mounted) {
        setState(() {
          _children = children;
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
          if (!_loading && _error == null && _children.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.directions_bus_rounded, size: 48, color: AppTheme.mutedLight),
                    SizedBox(height: 12),
                    Text('لا يوجد أطفال مسجلون في المواصلات', style: TextStyle(color: AppTheme.muted)),
                  ],
                ),
              ),
            ),
          ..._children.map((child) => _ChildTransportCard(
                child: child,
                onOpen: () => context.push('/parent/transport-trip', extra: child.studentId),
              )),
        ],
      ),
    );
  }
}

class _ChildTransportCard extends StatelessWidget {
  const _ChildTransportCard({required this.child, required this.onOpen});

  final ParentChildTransport child;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final trip = child.activeTrip;
    final status = _statusPresentation(trip);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: child.transportationEnabled ? onOpen : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: status.color.withValues(alpha: 0.15),
                    child: Icon(status.icon, color: status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transportDisplayName(child.name),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          child.transportationEnabled
                              ? (trip?.busNumber != null ? 'الحافلة ${trip!.busNumber}' : 'مسجّل في المواصلات')
                              : 'المواصلات غير مفعّلة',
                          style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status.label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: status.color)),
                  ),
                ],
              ),
              if (child.transportationEnabled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('متابعة الحافلة'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _StatusPresentation _statusPresentation(ParentActiveTrip? trip) {
    if (trip == null) {
      return const _StatusPresentation('لا رحلة نشطة', Icons.bedtime_rounded, AppTheme.muted);
    }
    return switch (trip.status) {
      'EMERGENCY' => const _StatusPresentation('طوارئ!', Icons.warning_rounded, AppTheme.coral),
      'NOT_STARTED' => const _StatusPresentation('لم تبدأ بعد', Icons.schedule_rounded, AppTheme.muted),
      'CANCELLED' => const _StatusPresentation('أُلغيت', Icons.cancel_rounded, AppTheme.honey),
      'COMPLETED' => const _StatusPresentation('اكتملت', Icons.check_circle_rounded, AppTheme.mint),
      'APPROACHING' => const _StatusPresentation('الحافلة تقترب', Icons.near_me_rounded, AppTheme.primary),
      'PICKED_UP' => const _StatusPresentation('طفلك على الحافلة', Icons.directions_bus_rounded, AppTheme.primary),
      'APPROACHING_DROPOFF' => const _StatusPresentation('تقترب من التوصيل', Icons.near_me_rounded, AppTheme.primary),
      'DROPPED_OFF' => const _StatusPresentation('تم التوصيل', Icons.home_rounded, AppTheme.mint),
      _ => const _StatusPresentation('الحافلة في الطريق', Icons.directions_bus_rounded, AppTheme.primary),
    };
  }
}

class _StatusPresentation {
  const _StatusPresentation(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
