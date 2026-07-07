import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/site_provider.dart';
import '../../core/providers/worker_provider.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.activeIcon, this.label, this.route);
}

const _navItems = [
  _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', '/'),
  _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Remaining', '/collections'),
  _NavItem(Icons.location_city_outlined, Icons.location_city, 'Sites', '/sites'),
  _NavItem(Icons.people_outline, Icons.people_rounded, 'Workers', '/workers'),
  _NavItem(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Attendance', '/attendance'),
  _NavItem(Icons.account_circle_outlined, Icons.account_circle_rounded, 'Account', '/account'),
];

int _indexFromRoute(String loc) {
  if (loc == '/') return 0;
  if (loc.startsWith('/collections')) return 1;
  if (loc.startsWith('/sites')) return 2;
  if (loc.startsWith('/workers')) return 3;
  if (loc.startsWith('/attendance')) return 4;
  if (loc.startsWith('/account')) return 5;
  return 0;
}

void _navigate(BuildContext ctx, int idx) {
  ctx.go(_navItems[idx].route);
}

class DashboardScreen extends StatelessWidget {
  final Widget child;
  const DashboardScreen({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFromRoute(loc);
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return isDesktop
        ? _DesktopLayout(selectedIndex: idx, child: child)
        : _MobileLayout(selectedIndex: idx, child: child);
  }
}

// ─────────────── DESKTOP LAYOUT ───────────────

class _DesktopLayout extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  const _DesktopLayout({required this.selectedIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                right: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              children: [
                // App header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
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
                ),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _navItems.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final selected = selectedIndex == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: ListTile(
                          leading: Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.65),
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          selected: selected,
                          selectedTileColor: cs.primaryContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          onTap: () => _navigate(context, i),
                          dense: true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading:
                        Icon(Icons.logout, color: cs.error.withValues(alpha: 0.8)),
                    title: Text('Logout',
                        style: TextStyle(color: cs.error.withValues(alpha: 0.8))),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      context.read<SiteProvider>().clear();
                      context.read<WorkerProvider>().clear();
                      auth.logout();
                      context.go('/login');
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
          // ── Content ──
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────── MOBILE LAYOUT ───────────────

class _MobileLayout extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  const _MobileLayout({required this.selectedIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: cs.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Worklist',
                      style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    '${auth.currentUser?.username ?? ''} · ${auth.currentUser?.role ?? ''}',
                    style: TextStyle(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _navItems.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final selected = selectedIndex == i;
                  return ListTile(
                    leading: Icon(selected ? item.activeIcon : item.icon,
                        color: selected ? cs.primary : null),
                    title: Text(item.label,
                        style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? cs.primary : null)),
                    selected: selected,
                    selectedColor: cs.primary,
                    selectedTileColor: cs.primaryContainer.withValues(alpha: 0.5),
                    onTap: () {
                      Navigator.pop(context);
                      _navigate(context, i);
                    },
                  );
                }).toList(),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: cs.error),
              title: Text('Logout', style: TextStyle(color: cs.error)),
              onTap: () {
                context.read<SiteProvider>().clear();
                context.read<WorkerProvider>().clear();
                auth.logout();
                context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _navigate(context, i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
