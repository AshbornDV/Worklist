import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../actions/notification_action_handler.dart';

/// Concrete [NotificationRouter] backed by the app's [GoRouter] instance.
/// Lives in the app shell (not the notification module) so the framework stays
/// decoupled from go_router.
class GoRouterNotificationRouter implements NotificationRouter {
  GoRouterNotificationRouter(this._router);

  final GoRouter _router;

  @override
  Future<void> navigate(String route) async {
    try {
      _router.go(route);
    } catch (e) {
      // Route may be invalid (e.g. entity deleted); fall back to the center.
      _router.go('/notifications');
    }
  }

  @override
  Future<void> openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
