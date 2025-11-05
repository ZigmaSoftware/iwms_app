import 'package:flutter/foundation.dart';

/// Handles all push / local notification responsibilities for the citizen app.
///
/// The concrete implementation is intentionally left as placeholders so the
/// real notification plumbing (Firebase Cloud Messaging, local notifications,
/// etc.) can be wired up later without impacting the rest of the codebase.
class NotificationService {
  /// Call this as early as possible (e.g. during app start) to set up the
  /// notification channels, request permissions, register tokens, and so on.
  Future<void> initialize() async {
    // TODO: Request notification permissions, configure channels and
    // initialise the notification plugin of your choice.
    debugPrint('[NotificationService] initialize() called (placeholder).');
  }

  /// Triggers a notification letting the citizen know the waste collector is
  /// nearby. This will eventually be replaced by real logic fed by location
  /// updates / schedules.
  Future<void> showCollectorNearbyNotification({
    String message = 'Waste collector is nearby! Get ready with your waste.',
  }) async {
    // TODO: Replace this placeholder with an actual push/local notification.
    debugPrint(
      '[NotificationService] showCollectorNearbyNotification(): $message',
    );
  }

  /// Schedules a future notification for scenarios such as pre-arrival alerts
  /// or daily reminders.
  Future<void> scheduleCollectorReminder({
    DateTime? triggerAt,
    String message = 'Waste collection scheduled soon. Prepare your waste.',
  }) async {
    // TODO: Use your scheduling API (e.g. zoned schedule in flutter_local_notifications).
    debugPrint(
      '[NotificationService] scheduleCollectorReminder(): '
      'triggerAt=$triggerAt message=$message',
    );
  }

  /// Cancels any previously scheduled collector notifications. Useful if the
  /// route changes or a pickup was completed early.
  Future<void> cancelCollectorNotifications() async {
    // TODO: Cancel the relevant scheduled notifications.
    debugPrint(
      '[NotificationService] cancelCollectorNotifications() called '
      '(placeholder).',
    );
  }
}
