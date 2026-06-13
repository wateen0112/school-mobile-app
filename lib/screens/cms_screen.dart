import 'package:flutter/material.dart';

import '../app/api_client.dart';
import '../app/design_system.dart';
import '../app/resource_registry.dart';
import '../widgets/shared_widgets.dart';
import 'attendance_screen.dart';
import 'resource_screen.dart';

class CmsScreen extends StatelessWidget {
  const CmsScreen({super.key, required this.api});

  final SchoolApiClient api;

  static const _attendanceDefinition = ResourceDefinition(
    key: 'attendance',
    titleKey: 'attendance',
    endpoint: '/attendance',
    icon: Icons.fact_check_rounded,
    categoryKey: 'studentsWorkflow',
    fields: [],
  );

  @override
  Widget build(BuildContext context) {
    final allResources = [...resourceDefinitions, _attendanceDefinition];
    final grouped = <String, List<ResourceDefinition>>{};
    for (final resource in allResources) {
      grouped.putIfAbsent(resource.categoryKey, () => []).add(resource);
    }

    return AppPage(
      title: t(context, 'cms'),
      child: ListView(
        children: [
          SoftCard(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xffffebe5),
                  foregroundColor: SchoolColors.secondary,
                  child: Icon(Icons.admin_panel_settings_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(context, 'cmsSubtitle'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in grouped.entries) ...[
            Text(
              t(context, entry.key),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entry.value.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.06,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final definition = entry.value[index];
                return SoftCard(
                  onTap: () => _open(context, definition),
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
                      StatusPill(
                        label: definition.canWrite
                            ? t(context, 'crud')
                            : t(context, 'readOnly'),
                        positive: definition.canWrite,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }

  void _open(BuildContext context, ResourceDefinition definition) {
    final page = definition.key == 'attendance'
        ? AttendanceScreen(api: api)
        : ResourceScreen(api: api, definition: definition);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
