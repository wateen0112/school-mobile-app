import 'package:flutter/material.dart';

import '../app/api_client.dart';
import '../app/app_state.dart';
import '../app/resource_registry.dart';
import '../widgets/shared_widgets.dart';
import 'attendance_screen.dart';
import 'cms_screen.dart';
import 'dashboard_screen.dart';
import 'resource_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appState, required this.api});

  final AppState appState;
  final SchoolApiClient api;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        appState: widget.appState,
        api: widget.api,
        openResource: _openResource,
      ),
      ResourceScreen(api: widget.api, definition: resourceByKey('students')),
      CmsScreen(api: widget.api),
      AttendanceScreen(api: widget.api),
      ResourceScreen(api: widget.api, definition: resourceByKey('settings')),
    ];
    return Directionality(
      textDirection: widget.appState.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        body: pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_rounded),
              label: t(context, 'dashboard'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_rounded),
              label: t(context, 'students'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              label: t(context, 'cms'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.fact_check_rounded),
              label: t(context, 'attendance'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_rounded),
              label: t(context, 'settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _openResource(ResourceDefinition definition) {
    if (definition.key == 'attendance') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: widget.appState.isArabic
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: AttendanceScreen(api: widget.api),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: widget.appState.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: ResourceScreen(api: widget.api, definition: definition),
        ),
      ),
    );
  }
}
