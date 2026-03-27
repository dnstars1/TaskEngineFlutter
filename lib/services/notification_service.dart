import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/assignment.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        linux: linuxSettings,
      ),
    );
    _initialized = true;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static String _leadTimeLabel(int minutes) {
    if (minutes >= 10080) return '${minutes ~/ 10080} week before';
    if (minutes >= 1440) {
      final days = minutes ~/ 1440;
      return '$days ${days == 1 ? 'day' : 'days'} before';
    }
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} before';
    }
    return '$minutes min before';
  }

  static Future<void> scheduleForAssignments(
    List<Assignment> assignments, {
    int leadTimeMinutes = 1440,
  }) async {
    await init();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final label = _leadTimeLabel(leadTimeMinutes);

    for (final assignment in assignments) {
      final notifyTime = tz.TZDateTime.from(
        assignment.dueDate.subtract(Duration(minutes: leadTimeMinutes)),
        tz.local,
      );

      if (notifyTime.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        id: assignment.id,
        title: 'Deadline $label',
        body: '${assignment.title} — ${assignment.courseName}',
        scheduledDate: notifyTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadlines',
            'Deadline Reminders',
            channelDescription: 'Notifications for upcoming assignment deadlines',
            importance: Importance.high,
            priority: Priority.high,
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
