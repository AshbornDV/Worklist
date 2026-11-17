import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/site_provider.dart';
import '../../core/providers/worker_provider.dart';

// Stable key for the mobile root Scaffold. A module-level key (not one
// created per-build) guarantees the drawer is always reachable from the
// hamburger and the "More" bottom item, even across route/provider rebuilds.
final GlobalKey<ScaffoldState> _mobileScaffoldKey =
    GlobalKey<ScaffoldState>();

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.activeIcon, this.label, this.route);
}

/// Exposes the root [ScaffoldState] key so nested screen scaffolds (each with
/// their own AppBar) can open the navigation drawer instead of their own
/// (drawer-less) scaffold.
class RootScaffoldKey extends InheritedWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const RootScaffoldKey({super.key, required this.scaffoldKey, required super.child});

  static GlobalKey<ScaffoldState>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootScaffoldKey>()?.scaffoldKey;

  @override
  bool updateShouldNotify(RootScaffoldKey old) => old.scaffoldKey != scaffoldKey;
}

// Bottom navigation (mobile) — 5 core destinations + a 6th "More" button
// that opens the drawer with the remaining destinations.
const _bottomNavItems = [
  _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', '/'),
  _NavItem(Icons.location_city_outlined, Icons.location_city, 'Sites', '/sites'),
  _NavItem(Icons.people_outline, Icons.people_rounded, 'Workers', '/workers'),
  _NavItem(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Attendance',
      '/attendance'),
  _NavItem(Icons.payments_outlined, Icons.payments_rounded, 'Payroll',
      '/payroll'),
  _NavItem(Icons.menu_outlined, Icons.menu_rounded, 'More', '/'),
];

// Full sidebar (tablet/desktop) — 10 destinations per reference.
const _sideNavItems = [
  _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', '/'),
  _NavItem(
      Icons.location_city_outlined, Icons.location_city, 'Sites', '/sites'),
  _NavItem(Icons.people_outline, Icons.people_rounded, 'Workers', '/workers'),
  _NavItem(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Attendance',
      '/attendance'),
  _NavItem(Icons.payments_outlined, Icons.payments_rounded, 'Payroll',
      '/payroll'),
  _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Products',
      '/products'),
  _NavItem(Icons.warehouse_outlined, Icons.warehouse_rounded, 'Stock', '/stock'),
  _NavItem(Icons.handyman_outlined, Icons.handyman_rounded, 'Services',
      '/services'),
  _NavItem(
      Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Collections',
      '/collections'),
  _NavItem(Icons.analytics_outlined, Icons.analytics_rounded, 'Analytics',
      '/analytics'),
  _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded,
      'Calendar', '/calendar'),
  _NavItem(
      Icons.account_circle_outlined, Icons.account_circle_rounded, 'Account',
      '/account'),
  _NavItem(Icons.folder_outlined, Icons.folder_rounded, 'Documents',
      '/documents'),
];

int _indexFromRoute(String loc) {
  if (loc == '/') return 0;
  if (loc.startsWith('/sites')) return 1;
  if (loc.startsWith('/workers')) return 2;
  if (loc.startsWith('/attendance')) return 3;
  if (loc.startsWith('/payroll')) return 4;
  if (loc.startsWith('/products')) return 5;
  if (loc.startsWith('/stock')) return 6;
  if (loc.startsWith('/services')) return 7;
  if (loc.startsWith('/collections')) return 8;
  if (loc.startsWith('/analytics')) return 9;
  if (loc.startsWith('/calendar')) return 10;
  if (loc.startsWith('/account')) return 11;
  if (loc.startsWith('/documents')) return 12;
  return 0;
}

void _navigate(BuildContext ctx, int idx) {
  ctx.go(_sideNavItems[idx].route);
}

class _AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  const _AppLogo({required this.size, this.radius = 7});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
}

class _SidebarTile extends StatelessWidget {
  final ColorScheme cs;
  final _NavItem item;
  final bool selected;
  final bool expanded;
  final bool isDestructive;
  final VoidCallback onTap;
  const _SidebarTile({
    required this.cs,
    required this.item,
    required this.selected,
    required this.expanded,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selected
        ? cs.primary
        : (isDestructive
            ? cs.error.withValues(alpha: 0.85)
            : cs.onSurface.withValues(alpha: 0.65));
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: expanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: activeColor,
              size: 22,
            ),
            if (expanded) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: activeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  final ColorScheme cs;
  final bool expanded;
  final VoidCallback onToggle;
  const _SidebarToggle({
    required this.cs,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onToggle,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 280),
              turns: expanded ? 0.0 : 0.5,
              child: Icon(
                Icons.chevron_left_rounded,
                color: cs.onSurface.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Widget child;
  const DashboardScreen({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFromRoute(loc);
    final width = MediaQuery.of(context).size.width;
    // Handheld (Android/iOS) → phone layout (drawer + 5-item bottom nav)
    // regardless of width, so a wide emulator (BlueStacks) still shows the
    // mobile UI. Rail/desktop only apply on larger widths or desktop OS.
    final isHandheld = kIsWeb ? false : (Platform.isAndroid || Platform.isIOS);
    if (isHandheld) {
      return _MobileLayout(
        selectedIndex: idx,
        scaffoldKey: _mobileScaffoldKey,
        child: child,
      );
    }
    if (width >= 1024) {
      return _CollapsibleSidebarShell(selectedIndex: idx, child: child);
    } else if (width >= 600) {
      return _TabletRailShell(selectedIndex: idx, child: child);
    }
    return _MobileLayout(
      selectedIndex: idx,
      scaffoldKey: _mobileScaffoldKey,
      child: child,
    );
  }
}

// ─────────────── MOBILE LAYOUT ───────────────

class _MobileLayout extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _MobileLayout({
    required this.selectedIndex,
    required this.child,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();

    // Bottom nav pins 5 core destinations; everything else lives in the
    // drawer (opened by the 6th "More" item or the hamburger).
    return Scaffold(
      key: scaffoldKey,
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const _AppLogo(size: 38, radius: 9),
                  ),
                  const SizedBox(height: 12),
                  const Text('Worklist',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22)),
                  const SizedBox(height: 3),
                  Text(
                    '${auth.currentUser?.username ?? ''} · ${auth.currentUser?.role ?? ''}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      tooltip: 'Notifications',
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/notifications');
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text('More destinations',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.5),
                            letterSpacing: 0.4)),
                  ),
                  ..._sideNavItems.skip(5).toList().asMap().entries.map((e) {
                    final i = e.key + 5;
                    final item = e.value;
                    final selected = selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        leading: Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected ? cs.primary : cs.onSurface),
                        title: Text(item.label,
                            style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected ? cs.primary : cs.onSurface)),
                        selected: selected,
                        selectedColor: cs.primary,
                        selectedTileColor:
                            cs.primaryContainer.withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          _navigate(context, i);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: Icon(Icons.logout, color: cs.error),
                      title: Text('Logout',
                          style: TextStyle(color: cs.error)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<SiteProvider>().clear();
                        context.read<WorkerProvider>().clear();
                        auth.logout();
                        context.go('/login');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RootScaffoldKey(scaffoldKey: scaffoldKey, child: child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                _BottomBarItem(
                  item: _bottomNavItems[i],
                  selected: selectedIndex == i,
                  onTap: () => _navigate(context, i),
                ),
              ],
              _BottomBarItem(
                item: _bottomNavItems[5],
                selected: false,
                // "More" always opens the drawer, even if already selected.
                onTap: () => scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _BottomBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? cs.primary : cs.onSurface,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? cs.primary : cs.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── TABLET RAIL LAYOUT ───────────────

class _TabletRailShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  const _TabletRailShell({required this.selectedIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();
    final width = MediaQuery.of(context).size.width;
    final labels = width >= 700;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: labels ? 220 : 74,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                right: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
                  child: Row(
                    mainAxisAlignment: labels
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      const _AppLogo(size: 30, radius: 8),
                      if (labels) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Worklist',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _sideNavItems.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final selected = selectedIndex == i;
                      return _SidebarTile(
                        cs: cs,
                        item: item,
                        selected: selected,
                        expanded: labels,
                        onTap: () => _navigate(context, i),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: _SidebarTile(
                    cs: cs,
                    item: const _NavItem(Icons.logout_rounded, Icons.logout_rounded,
                        'Logout', ''),
                    selected: false,
                    expanded: labels,
                    isDestructive: true,
                    onTap: () {
                      context.read<SiteProvider>().clear();
                      context.read<WorkerProvider>().clear();
                      auth.logout();
                      context.go('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────── DESKTOP COLLAPSIBLE SIDEBAR ───────────────

class _CollapsibleSidebarShell extends StatefulWidget {
  final int selectedIndex;
  final Widget child;
  const _CollapsibleSidebarShell({
    required this.selectedIndex,
    required this.child,
  });

  @override
  State<_CollapsibleSidebarShell> createState() =>
      _CollapsibleSidebarShellState();
}

class _CollapsibleSidebarShellState extends State<_CollapsibleSidebarShell> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();
    final target = _expanded ? 260.0 : 72.0;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            width: target,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                right: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              children: [
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _AppLogo(size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Worklist',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: cs.primary,
                              child: Text(
                                (auth.currentUser?.username ?? 'A')[0]
                                    .toUpperCase(),
                                style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.currentUser?.username ?? 'User',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onPrimaryContainer),
                                  ),
                                  Text(
                                    auth.currentUser?.role.toUpperCase() ?? '',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onPrimaryContainer
                                            .withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: _AppLogo(size: 28),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _sideNavItems.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final selected = widget.selectedIndex == i;
                      return _SidebarTile(
                        cs: cs,
                        item: item,
                        selected: selected,
                        expanded: _expanded,
                        onTap: () => _navigate(context, i),
                      );
                    }).toList(),
                  ),
                ),
                _SidebarToggle(
                  cs: cs,
                  expanded: _expanded,
                  onToggle: () {
                    if (mounted) setState(() => _expanded = !_expanded);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: _SidebarTile(
                    cs: cs,
                    item: const _NavItem(Icons.logout_rounded, Icons.logout_rounded,
                        'Logout', ''),
                    selected: false,
                    expanded: _expanded,
                    isDestructive: true,
                    onTap: () {
                      context.read<SiteProvider>().clear();
                      context.read<WorkerProvider>().clear();
                      auth.logout();
                      context.go('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
