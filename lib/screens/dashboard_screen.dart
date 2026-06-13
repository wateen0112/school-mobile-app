import 'package:flutter/material.dart';

import '../app/api_client.dart';
import '../app/app_state.dart';
import '../app/design_system.dart';
import '../app/resource_registry.dart';
import '../widgets/shared_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.appState,
    required this.api,
    required this.openResource,
  });

  final AppState appState;
  final SchoolApiClient api;
  final ValueChanged<ResourceDefinition> openResource;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _future = widget.api.getDashboard();

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: t(context, 'dashboard'),
      actions: [
        IconButton(
          tooltip: t(context, 'language'),
          onPressed: () => widget.appState.setLocale(
            widget.appState.isArabic ? const Locale('en') : const Locale('ar'),
          ),
          icon: const Icon(Icons.language_rounded),
        ),
        IconButton(
          tooltip: t(context, 'logout'),
          onPressed: widget.api.logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async =>
            setState(() => _future = widget.api.getDashboard()),
        child: ListView(
          children: [
            _Header(appState: widget.appState),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                final stats =
                    snapshot.data?['stats'] as Map<String, dynamic>? ??
                    const {};
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: t(context, 'statsStudents'),
                        value: '${stats['students_count'] ?? '-'}',
                        icon: Icons.school_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: t(context, 'statsTeachers'),
                        value: '${stats['teachers_count'] ?? '-'}',
                        icon: Icons.badge_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: t(context, 'statsClasses'),
                        value: '${stats['classrooms_count'] ?? '-'}',
                        icon: Icons.meeting_room_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              t(context, 'recentWorkflows'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resourceDefinitions.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.18,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final definition = index == 8
                    ? const ResourceDefinition(
                        key: 'attendance',
                        titleKey: 'attendance',
                        endpoint: '/attendance',
                        icon: Icons.fact_check_rounded,
                        fields: [],
                      )
                    : resourceDefinitions[index > 8 ? index - 1 : index];
                return SoftCard(
                  onTap: () => widget.openResource(definition),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: SchoolColors.primary.withValues(
                          alpha: .1,
                        ),
                        foregroundColor: SchoolColors.primary,
                        child: Icon(definition.icon),
                      ),
                      const Spacer(),
                      Text(
                        t(context, definition.titleKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        definition.endpoint,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SchoolColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: SchoolGradients.promo,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: SchoolColors.primary.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(context, 'appName'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${appState.userName ?? ''}  ${appState.userType ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .84),
                  ),
                ),
              ],
            ),
          ),
          const SchoolBagIllustration(size: 92),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SchoolColors.secondary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: SchoolColors.muted),
          ),
        ],
      ),
    );
  }
}
