import 'dart:developer' as dev;

/// Structured logger for the notification framework. Keeps notification
/// diagnostics isolated from the app's general debug output and allows a
/// future debug console / analytics sink to be plugged in without touching
/// call sites.
class NotificationLogger {
  NotificationLogger._();

  static final NotificationLogger instance = NotificationLogger._();

  static const String _tag = 'Worklist:Notifications';

  /// Minimum level that will actually emit. Bump to [Level.warning] in
  /// production builds to silence verbose engine chatter.
  Level minLevel = Level.info;

  void verbose(String message, [Object? data]) =>
      _log(Level.verbose, message, data);

  void info(String message, [Object? data]) => _log(Level.info, message, data);

  void warning(String message, [Object? data]) =>
      _log(Level.warning, message, data);

  void error(String message, [Object? error, StackTrace? stack]) {
    if (Level.error.index < minLevel.index) return;
    dev.log(
      '$_tag ERROR $message',
      name: _tag,
      error: error,
      stackTrace: stack,
    );
  }

  void _log(Level level, String message, [Object? data]) {
    if (level.index < minLevel.index) return;
    final buffer = data != null ? '$message data=$data' : message;
    dev.log('$_tag [${level.name}] $buffer', name: _tag);
  }
}

enum Level {
  verbose,
  info,
  warning,
  error,
}

extension LevelX on Level {
  String get name => toString().split('.').last;
}
