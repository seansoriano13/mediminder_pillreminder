import 'dart:async';

/// Web-compatible notification service.
/// On web, flutter_local_notifications is not supported, so we use a
/// periodic Timer to trigger UI refresh in the Today screen every minute.
/// On native, this would initialize flutter_local_notifications.
class NotificationService {
  static Timer? _periodicTimer;
  static Function()? _onMinuteTick;

  static Future<void> initialize() async {
    _startPeriodicTimer();
  }

  static void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_onMinuteTick != null) {
        _onMinuteTick!();
      }
    });
  }

  /// Register a callback that is called every minute.
  /// The Today screen uses this to refresh overdue statuses.
  static void registerTickCallback(Function() callback) {
    _onMinuteTick = callback;
  }

  static void unregisterTickCallback() {
    _onMinuteTick = null;
  }

  static void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _onMinuteTick = null;
  }
}
