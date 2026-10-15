import 'dart:ui';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../features/notifications/notification_dropdown.dart';
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
    final isParent = session.currentRole == UserRole.parent;
    final showBottomBar =
        !isParent && _isBottomBarRoute(mobileItems, currentPath);
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
              toolbarHeight: 64,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: isParent ? const _ParentChildSwitcher() : null,
              leading: isParent
                  ? (currentPath == session.homeRoute
                      ? null
                      : _ParentBackButton(homeRoute: session.homeRoute))
                  : Builder(
                      builder: (context) => _ShellIconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: Icons.menu_rounded,
                        tooltip: appIsArabic(context)
                            ? 'فتح القائمة'
                            : 'Open menu',
                      ),
                    ),
              actions: [
                _NotificationDropdown(session: session),
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
                        if (context.mounted) context.go('/login');
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Text(t(context, 'profile')),
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
            drawer: isParent
                ? null
                : _RoleDrawer(groups: groups, currentPath: currentPath),
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

class _NotificationDropdown extends StatefulWidget {
  const _NotificationDropdown({required this.session});

  final SessionController session;

  @override
  State<_NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<_NotificationDropdown> {
  OverlayEntry? _overlayEntry;

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Calculate dropdown position to keep it within screen bounds
    double dropdownWidth = 320;
    double left;
    if (isRtl) {
      // For RTL: align left edge of dropdown with left edge of bell icon
      left = position.dx;
    } else {
      // For LTR: align right edge of dropdown with right edge of bell icon
      left = position.dx + size.width - dropdownWidth;
    }
    // Clamp to screen bounds
    left = left.clamp(8.0, screenWidth - dropdownWidth - 8.0);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              left: left,
              top: position.dy + size.height + 8,
              child: NotificationDropdownMenu(
                session: widget.session,
                onClose: _closeDropdown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: widget.session.unreadNotificationCount > 0
          ? Text(
              '${widget.session.unreadNotificationCount > 99 ? '99+' : widget.session.unreadNotificationCount}',
            )
          : null,
      backgroundColor: AppTheme.coral,
      child: _ShellIconButton(
        onPressed: _toggleDropdown,
        icon: Icons.notifications_rounded,
        tooltip: appIsArabic(context) ? 'الإشعارات' : 'Notifications',
      ),
    );
  }
}

class _RoleDrawer extends StatelessWidget {
  const _RoleDrawer({required this.groups, required this.currentPath});

  final List<NavGroup> groups;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.coral,
                ),
                title: Text(
                  t(context, 'logout'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.coral,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  session.logout().then((_) {
                    if (context.mounted) context.go('/login');
                  });
                },
              ),
            ),
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
    if (items.isEmpty) return const SizedBox.shrink();
    final safeSelectedIndex = selectedIndex.clamp(0, items.length - 1);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xCCE2E8F0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 30,
                    spreadRadius: -5,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _BottomBarItem(
                        item: items[i],
                        selected: i == safeSelectedIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatefulWidget {
  const _BottomBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_BottomBarItem> createState() => _BottomBarItemState();
}

class _BottomBarItemState extends State<_BottomBarItem> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final label = localizedNavLabel(context, widget.item);
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? .95 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              vertical: 10,
              horizontal: selected ? 16 : 12,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x40F97316),
                        blurRadius: 6,
                        spreadRadius: -1,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Color(0x40F97316),
                        blurRadius: 4,
                        spreadRadius: -2,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  size: 20,
                  color: selected ? Colors.white : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentBackButton extends StatelessWidget {
  const _ParentBackButton({required this.homeRoute});

  final String homeRoute;

  @override
  Widget build(BuildContext context) {
    return _ShellIconButton(
      onPressed: () {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(homeRoute);
        }
      },
      icon: Icons.arrow_back_rounded,
      tooltip: appIsArabic(context) ? 'رجوع' : 'Back',
    );
  }
}

/// Parent-only app bar widget that always shows the currently selected
/// child and lets the parent switch the active child from anywhere.
class _ParentChildSwitcher extends StatefulWidget {
  const _ParentChildSwitcher();

  @override
  State<_ParentChildSwitcher> createState() => _ParentChildSwitcherState();
}

class _ParentChildSwitcherState extends State<_ParentChildSwitcher> {
  List<Map<String, dynamic>> _children = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final api = context.read<SessionController>().api;
      final body = await api.get('/Students');
      final data = body['data'];
      if (!mounted) return;
      setState(() {
        _children = data is List
            ? data
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : [];
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Map<String, dynamic>? _selectedChild(int? selectedId) {
    if (selectedId == null) return null;
    for (final child in _children) {
      if ('${child['id']}' == '$selectedId') return child;
    }
    return null;
  }

  Future<void> _openSwitcher(int? selectedId) async {
    final isArabic = appIsArabic(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isArabic ? 'اختر الابن' : 'Select child',
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final child in _children)
                        Builder(
                          builder: (context) {
                            final id = child['id'];
                            final selected =
                                selectedId != null && '$id' == '$selectedId';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: selected
                                    ? AppTheme.primary
                                    : AppTheme.cloud,
                                child: Icon(
                                  Icons.child_care_rounded,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.primary,
                                ),
                              ),
                              title: Text(
                                '${child['name'] ?? ''}',
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.primary,
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onTap: () {
                                if (id is int) {
                                  context
                                      .read<AppState>()
                                      .setSelectedChild(id);
                                }
                                Navigator.of(sheetContext).pop();
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = context.watch<AppState>().selectedChildId;
    final selected = _selectedChild(selectedId);
    final isArabic = appIsArabic(context);

    final label = selected != null
        ? '${selected['name'] ?? ''}'
        : !_loaded
            ? '…'
            : (isArabic ? 'اختر الابن' : 'Select child');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _children.isEmpty ? null : () => _openSwitcher(selectedId),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xCCE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: .10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.child_care_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppTheme.muted,
              ),
            ],
          ),
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
        constraints: const BoxConstraints.tightFor(
          width: 44,
          height: 44,
        ),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primary,
          shadowColor: AppTheme.primary.withValues(alpha: .12),
          elevation: 4,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
