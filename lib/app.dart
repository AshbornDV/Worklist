import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/actions/app_notification_router.dart';
import 'core/notifications/actions/notification_action_handler.dart';
import 'core/notifications/platform/android_notification_service.dart';
import 'core/notifications/platform/platform_notification_service_factory.dart';
import 'core/notifications/platform/windows_notification_service.dart';
import 'core/notifications/repositories/notification_history_repository.dart';
import 'features/account/account_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/home_content.dart';
import 'features/dashboard/collections_screen.dart';
import 'features/dashboard/analytics_screen.dart';
import 'features/dashboard/calendar_screen.dart';
import 'features/documents/screens/documents_screen.dart';
import 'features/payroll/payroll_screen.dart';
import 'features/products/products_screen.dart';
import 'features/services/services_screen.dart';
import 'features/sites/site_detail_screen.dart';
import 'features/stock/stock_screen.dart';
import 'features/sites/site_form_screen.dart';
import 'features/sites/sites_list_screen.dart';
import 'features/workers/attendance_screen.dart';
import 'features/workers/worker_detail_screen.dart';
import 'features/workers/worker_form_screen.dart';
import 'features/workers/workers_list_screen.dart';
import 'features/notifications/notification_center_screen.dart';
import 'features/notifications/notification_diagnostics_screen.dart';
import 'features/notifications/business_insight_screen.dart';
import 'features/notifications/notification_settings_screen.dart';

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
    final router = GoRouter(
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
            GoRoute(
                path: '/collections',
                builder: (_, __) => const CollectionsScreen()),
            GoRoute(
                path: '/analytics',
                builder: (_, __) => const AnalyticsScreen()),
            GoRoute(
                path: '/calendar',
                builder: (_, __) => const CalendarScreen()),
            GoRoute(
                path: '/documents',
                builder: (_, __) => const DocumentsScreen()),
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
                path: '/payroll', builder: (_, __) => const PayrollScreen()),
            GoRoute(
                path: '/products', builder: (_, __) => const ProductsScreen()),
            GoRoute(path: '/stock', builder: (_, __) => const StockScreen()),
            GoRoute(
                path: '/services', builder: (_, __) => const ServicesScreen()),
            GoRoute(
                path: '/notifications',
                builder: (_, __) =>
                    const NotificationCenterScreenWithProvider()),
            GoRoute(
                path: '/notifications/settings',
                builder: (_, __) =>
                    const NotificationSettingsScreenWithProvider()),
            GoRoute(
                path: '/notifications/diagnostics',
                builder: (_, __) => const NotificationDiagnosticsScreen()),
            GoRoute(
                path: '/notifications/insights',
                builder: (_, __) => const BusinessInsightScreen()),
            GoRoute(
              path: '/account', builder: (_, __) => const AccountScreen()),
          ],
        ),
      ],
    );
    _wireActionHandler(router);
    return router;
  }

  /// Phase 9: wires the interactive-notification action handler once the
  /// router + history repo are available. Runs once.
  Future<void> _wireActionHandler(GoRouter router) async {
    if (_handlerWired) return;
    _handlerWired = true;
    final history = await NotificationHistoryRepository.create();
    final handler = NotificationActionHandler(
      history: history,
      router: GoRouterNotificationRouter(router),
      platform: PlatformNotificationServiceFactory.instance,
    );
    AndroidNotificationService.actionHandler = handler;
    WindowsNotificationService.actionHandler = handler;
  }

  bool _handlerWired = false;

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final themeMode = context.watch<ThemeProvider>().mode;
    return MaterialApp.router(
      title: 'Worklist',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}
