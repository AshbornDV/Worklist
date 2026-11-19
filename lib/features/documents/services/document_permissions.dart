/// Document Management — runtime permission orchestration.
///
/// Centralizes every Android/iOS permission the document feature needs and
/// shows a human explanation BEFORE prompting (and again when permanently
/// denied, with a deep-link to App Settings). Every entry point that touches
/// the camera, gallery, file picker, or notifications must route through here
/// so the app never crashes or hangs on a missing permission.
///
/// Permission matrix (scoped storage, Android 10–15):
///   • Camera capture      → CAMERA
///   • Gallery / file pick → READ_MEDIA_IMAGES/VIDEO/AUDIO (API 33+) or
///                           READ_EXTERNAL_STORAGE (API 29–32)
///   • Post notifications  → POST_NOTIFICATIONS (API 33+)
library;

import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

/// What a permission is needed for — drives the explanation copy.
enum _PermUse { camera, gallery, notifications }

class DocumentPermissions {
  DocumentPermissions._();
  static final DocumentPermissions instance = DocumentPermissions._();

  /// Request camera access. Returns true only if the camera can be used.
  Future<bool> requestCamera(BuildContext context) {
    debugPrint('[DocPerms] requestCamera()');
    return _ensure(context, Permission.camera, _PermUse.camera);
  }

  /// Request whatever media/gallery permission the running OS requires.
  /// [Permission.photos] auto-maps to READ_MEDIA_IMAGES on Android 13+ and
  /// READ_EXTERNAL_STORAGE on Android 10–12 (handled by permission_handler).
  Future<bool> requestGallery(BuildContext context) {
    debugPrint('[DocPerms] requestGallery()');
    return _ensure(context, Permission.photos, _PermUse.gallery);
  }

  /// Request the post-notifications permission (no-op / granted on < API 33).
  Future<bool> requestNotifications(BuildContext context) {
    debugPrint('[DocPerms] requestNotifications()');
    return _ensure(context, Permission.notification, _PermUse.notifications);
  }

  /// Context-free request used at app launch (Android shows its own system
  /// prompt, so no in-app explanation is needed). Safe to call before a
  /// BuildContext exists.
  Future<void> requestNotificationsAtLaunch() async {
    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint('[DocPerms] notification request skipped: $e');
    }
  }
  Future<bool> _ensure(
    BuildContext context,
    Permission permission,
    _PermUse use,
  ) async {
    PermissionStatus status;
    try {
      status = await permission.status;
    } catch (e) {
      debugPrint('[DocPerms] status check failed (non-fatal): $e');
      status = PermissionStatus.denied;
    }

    if (status.isGranted) return true;

    // Explain WHY before prompting (first-time / provisional).
    if (status.isLimited || status.isRestricted) return true;
    if (status.isDenied) {
      if (!context.mounted) return false;
      final ok = await _explain(context, use);
      if (!ok) return false;
      try {
        status = await permission.request();
      } catch (e) {
        debugPrint('[DocPerms] request failed (non-fatal): $e');
        return false;
      }
      if (status.isGranted) return true;
      // User denied this time too.
      if (status.isPermanentlyDenied) {
        if (!context.mounted) return false;
        await _showSettings(context, use);
      } else {
        if (!context.mounted) return false;
        await _showDenied(context, use);
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettings(context, use);
      return false;
    }

    // Any other non-granted state → attempt a direct request once.
    try {
      status = await permission.request();
    } catch (e) {
      debugPrint('[DocPerms] request failed (non-fatal): $e');
      return false;
    }
    debugPrint('[DocPerms] result for $use: ${status.name}');
    return status.isGranted;
  }

  /// Returns true if the user agreed to proceed to the system prompt.
  Future<bool> _explain(BuildContext context, _PermUse use) async {
    final data = _copy(use);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.title),
        content: Text(data.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showDenied(BuildContext context, _PermUse use) async {
    final data = _copy(use);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data.title} was denied. You can enable it later.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showSettings(BuildContext context, _PermUse use) async {
    final data = _copy(use);
    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${data.title} required'),
        content: Text(
          '${data.body}\n\n'
          'This permission was denied permanently. Open App Settings to enable it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (go == true) {
      try {
        await openAppSettings();
      } catch (e) {
        debugPrint('[DocPerms] openAppSettings failed: $e');
      }
    }
  }

  _Copy _copy(_PermUse use) {
    switch (use) {
      case _PermUse.camera:
        return const _Copy(
          title: 'Camera access',
          body: 'Worklist needs camera access to capture photos of site '
              'documents, ID proofs and receipts.',
        );
      case _PermUse.gallery:
        return const _Copy(
          title: 'Media access',
          body: 'Worklist needs access to your photos and files so you can '
              'attach existing images, PDFs, Word and Excel documents.',
        );
      case _PermUse.notifications:
        return const _Copy(
          title: 'Notifications',
          body: 'Worklist sends reminders for upcoming site tasks, payroll '
              'and document follow-ups. Allow notifications to receive them.',
        );
    }
  }
}

class _Copy {
  const _Copy({required this.title, required this.body});
  final String title;
  final String body;
}
