import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/school_modules.dart';
import '../localization/module_localization.dart';
import '../models/app_models.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, this.navigationShell});

  final Widget child;
  final StatefulNavigationShell? navigationShell;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final currentPath = GoRouterState.of(context).uri.path;
    final groups = navGroupsForRole(session.currentRole);
    final mobileItems = _primaryMobileItems(session.currentRole);
    final showBottomBar = _isBottomBarRoute(mobileItems, currentPath);
    final mobileSelectedIndex =
        navigationShell?.currentIndex ??
        _selectedIndex(mobileItems, currentPath);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            appBar: AppBar(
              toolbarHeight: 72,
              automaticallyImplyLeading: false,
              leading: Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: appIsArabic(context) ? 'فتح القائمة' : 'Open menu',
                ),
              ),
              title: _PageTitle(path: currentPath),
              actions: [
                Badge(
                  label: const Text('3'),
                  backgroundColor: AppTheme.coral,
                  child: _ShellIconButton(
                    onPressed: () {},
                    icon: Icons.notifications_rounded,
                    tooltip: 'Notifications',
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.ctaGradient,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      context.go('/${session.currentRole.name}/profile');
                    }
                    if (value == 'toggleChucker') {
                      session.toggleChucker();
                    }
                    if (value == 'apiInspector' && session.showChucker) {
                      ChuckerFlutter.showChuckerScreen();
                    }
                    if (value == 'logout') {
                      session.logout().then((_) {
                        if (context.mounted) context.go('/roles');
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Text(t(context, 'profile')),
                    ),
                    PopupMenuItem(
                      value: 'toggleChucker',
                      child: Row(
                        children: [
                          Icon(
                            session.showChucker
                                ? Icons.bug_report_rounded
                                : Icons.bug_report_outlined,
                            color: session.showChucker ? AppTheme.coral : AppTheme.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            session.showChucker
                                ? 'Disable API Inspector'
                                : 'Enable API Inspector',
                          ),
                        ],
                      ),
                    ),
                    if (session.showChucker)
                      PopupMenuItem(
                        value: 'apiInspector',
                        child: Text(t(context, 'apiInspector')),
                      ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Text(t(context, 'logout')),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
              ],
            ),
            drawer: _RoleDrawer(groups: groups, currentPath: currentPath),
            body: child,
            floatingActionButton: session.showChucker
                ? FloatingActionButton.small(
                    heroTag: 'chucker_fab',
                    backgroundColor: AppTheme.coral,
                    foregroundColor: Colors.white,
                    onPressed: () => ChuckerFlutter.showChuckerScreen(),
                    child: const Icon(Icons.network_check_rounded),
                  )
                : null,
            bottomNavigationBar: showBottomBar
                ? _FloatingBottomBar(
                    items: mobileItems,
                    selectedIndex: mobileSelectedIndex,
                    onTap: (index) => _onBottomBarTap(
                      context,
                      index: index,
                      mobileItems: mobileItems,
                      currentPath: currentPath,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  bool _isBottomBarRoute(List<NavItem> items, String currentPath) {
    return items.any(
      (item) =>
          currentPath == item.route || currentPath.startsWith('${item.route}/'),
    );
  }

  int _selectedIndex(List<NavItem> items, String currentPath) {
    if (items.isEmpty) return 0;
    final index = items.indexWhere(
      (item) =>
          currentPath == item.route || currentPath.startsWith('${item.route}/'),
    );
    return index < 0 ? 0 : index;
  }

  void _onBottomBarTap(
    BuildContext context, {
    required int index,
    required List<NavItem> mobileItems,
    required String currentPath,
  }) {
    if (index < 0 || index >= mobileItems.length) return;
    final route = mobileItems[index].route;
    if (route == currentPath) return;

    final shell = navigationShell;
    if (shell != null) {
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
      return;
    }

    GoRouter.of(context).go(route);
  }

  List<NavItem> _primaryMobileItems(UserRole role) {
    return primaryMobileModulesForRole(role)
        .map(
          (module) => NavItem(
            label: module.title,
            icon: module.icon,
            route: module.route,
          ),
        )
        .toList();
  }
}

class _RoleDrawer extends StatelessWidget {
  const _RoleDrawer({required this.groups, required this.currentPath});

  final List<NavGroup> groups;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  localizedGroupLabel(context, group.label),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
              ),
              for (final item in group.items)
                _DrawerNavTile(
                  item: item,
                  selected: item.route == currentPath,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (item.route != currentPath) {
                      GoRouter.of(context).go(item.route);
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: selected ? AppTheme.primary : AppTheme.muted,
      ),
      title: Text(
        localizedNavLabel(context, item),
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppTheme.ink : AppTheme.muted,
        ),
      ),
      selected: selected,
      selectedTileColor: AppTheme.cloud,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const barHeight = 58.0;
    const activeSize = 58.0;
    if (items.isEmpty) return const SizedBox.shrink();
    final safeSelectedIndex = selectedIndex.clamp(0, items.length - 1);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = items.length;
                final slotWidth = constraints.maxWidth / count;
                final selectedLeft =
                    (slotWidth * safeSelectedIndex) +
                    (slotWidth - activeSize) / 2;
                final barTop = constraints.maxHeight - barHeight;
                final selectedTop = barTop - (activeSize / 2);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.ink.withValues(alpha: .13),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            for (var index = 0; index < items.length; index++)
                              Expanded(
                                child: _BottomBarItem(
                                  item: items[index],
                                  selected: index == selectedIndex,
                                  onTap: () => onTap(index),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      left: selectedLeft,
                      top: selectedTop,
                      child: _RaisedBottomAction(
                        item: items[safeSelectedIndex],
                        onTap: () => onTap(safeSelectedIndex),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = localizedNavLabel(context, item);
    return Tooltip(
      message: label,
      child: IgnorePointer(
        ignoring: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: Center(
              child: Opacity(
                opacity: selected ? 0 : 1,
                child: Icon(
                  item.icon,
                  color: const Color(0xffb8bfd2),
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaisedBottomAction extends StatelessWidget {
  const _RaisedBottomAction({required this.item, required this.onTap});

  final NavItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = localizedNavLabel(context, item);
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: AppTheme.ctaGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.surface, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.coral.withValues(alpha: .30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(item.icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _ShellIconButton extends StatelessWidget {
  const _ShellIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primary,
          shadowColor: AppTheme.primary.withValues(alpha: .12),
          elevation: 4,
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final current = localizedPageTitle(context, path);
    return Text(
      current,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w900),
    );
  }
}
