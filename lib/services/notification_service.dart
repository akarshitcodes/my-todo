import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'task_reminders';

  static const String _channelName = 'Task Reminders';

  static const String _channelDescription =
      'Notifications for task reminders';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    final timezoneInfo =
        await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          _onNotificationTapped,
    );

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    final payload = response.payload;

    if (payload == null) {
      return;
    }

    // Later we will use this payload to open
    // the corresponding task.
  }

  // ---------------------------------------------------------------------------
  // DETERMINISTIC NOTIFICATION ID
  // ---------------------------------------------------------------------------

  int notificationIdForTask(String taskId) {
    // FNV-1a style deterministic hash.
    // This gives the same notification ID for
    // the same task ID across app launches.
    var hash = 0x811C9DC5;

    for (final codeUnit in taskId.codeUnits) {
      hash ^= codeUnit;
      hash =
          (hash * 0x01000193) & 0x7fffffff;
    }

    return hash == 0 ? 1 : hash;
  }

  // ---------------------------------------------------------------------------
  // SCHEDULE TASK REMINDER
  // ---------------------------------------------------------------------------

  Future<void> scheduleTaskReminder(Task task) async {
    final notificationId =
        notificationIdForTask(task.id);

    // Remove an old scheduled reminder first.
    await _plugin.cancel(id: notificationId);

    final reminderAt = task.reminderAt;

    if (reminderAt == null) {
      return;
    }

    if (!reminderAt.isAfter(DateTime.now())) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(
      reminderAt,
      tz.local,
    );

    const androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Task Reminder 🔔',
      body: task.title,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'task:${task.id}',
    );
  }

  // ---------------------------------------------------------------------------
  // CANCEL TASK REMINDER
  // ---------------------------------------------------------------------------

  Future<void> cancelTaskReminder(
    String taskId,
  ) async {
    final notificationId =
        notificationIdForTask(taskId);

    await _plugin.cancel(id: notificationId);
  }

  // ---------------------------------------------------------------------------
  // SYNC TASK REMINDER
  // ---------------------------------------------------------------------------

  Future<void> syncTaskReminder(Task task) async {
    if (task.isCompleted ||
        task.reminderAt == null) {
      await cancelTaskReminder(task.id);
      return;
    }

    await scheduleTaskReminder(task);
  }

  // ---------------------------------------------------------------------------
  // TEST NOTIFICATION
  // ---------------------------------------------------------------------------

  Future<void> showTestNotification() async {
    const androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: 999999,
      title: 'To-Do Reminder 🔔',
      body: 'This is a test notification.',
      notificationDetails: details,
    );
  }

  // ---------------------------------------------------------------------------
  // TEST SCHEDULED NOTIFICATION
  // ---------------------------------------------------------------------------

  Future<void> scheduleTestNotification() async {
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(
      const Duration(seconds: 10),
    );

    const androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.zonedSchedule(
      id: 999998,
      title: 'To-Do Reminder 🔔',
      body:
          'Your scheduled test notification fired.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'test',
    );
  }
}