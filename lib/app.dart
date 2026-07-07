import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/account/account_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/home_content.dart';
import 'features/dashboard/collections_screen.dart';
import 'features/sync/sync_screen.dart';
import 'features/sites/site_detail_screen.dart';
import 'features/sites/site_form_screen.dart';
import 'features/sites/sites_list_screen.dart';
import 'features/workers/attendance_screen.dart';
import 'features/workers/worker_detail_screen.dart';
import 'features/workers/worker_form_screen.dart';
import 'features/workers/workers_list_screen.dart';

class SiteWorkerManagerApp extends StatefulWidget {
  const SiteWorkerManagerApp({super.key});

  @override
  State<SiteWorkerManagerApp> createState() => _SiteWorkerManagerAppState();
}

class _SiteWorkerManagerAppState extends State<SiteWorkerManagerApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= _buildRouter();
  }

  GoRouter _buildRouter() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return GoRouter(
      initialLocation: auth.isLoggedIn ? '/' : '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final isLoggedIn = auth.isLoggedIn;
        final isLoginPage = state.matchedLocation == '/login';
        if (!isLoggedIn && !isLoginPage) return '/login';
        if (isLoggedIn && isLoginPage) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => DashboardScreen(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeContent()),
            GoRoute(path: '/collections', builder: (_, __) => const CollectionsScreen()),
            GoRoute(
                path: '/sites', builder: (_, __) => const SitesListScreen()),
            GoRoute(
                path: '/sites/new', builder: (_, __) => const SiteFormScreen()),
            GoRoute(
              path: '/sites/:id',
              builder: (_, state) => SiteDetailScreen(
                siteId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/sites/:id/edit',
              builder: (_, state) => SiteFormScreen(
                siteId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
                path: '/workers',
                builder: (_, __) => const WorkersListScreen()),
            GoRoute(
                path: '/workers/new',
                builder: (_, __) => const WorkerFormScreen()),
            GoRoute(
              path: '/workers/:id',
              builder: (_, state) => WorkerDetailScreen(
                workerId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/workers/:id/edit',
              builder: (_, state) => WorkerFormScreen(
                workerId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
                path: '/attendance',
                builder: (_, __) => const AttendanceScreen()),
            GoRoute(
                path: '/sync', builder: (_, __) => const SyncScreen()),
            GoRoute(
                path: '/account', builder: (_, __) => const AccountScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Worklist',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}
