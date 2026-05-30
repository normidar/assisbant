import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>(
  (_) => throw UnimplementedError('Override localNotificationsProvider in ProviderScope'),
);

Future<FlutterLocalNotificationsPlugin> initLocalNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const macosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
    macOS: macosSettings,
  );

  await plugin.initialize(initSettings);
  return plugin;
}

Future<void> showTaskCompletedNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
) async {
  const androidDetails = AndroidNotificationDetails(
    'assisbant_task_completed',
    'Task Completed',
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails();
  const macosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
    macOS: macosDetails,
  );

  final truncatedTitle = title.length > 100 ? '${title.substring(0, 100)}…' : title;
  final truncatedBody = body.length > 300 ? '${body.substring(0, 300)}…' : body;

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch % 100000,
    truncatedTitle,
    truncatedBody.isEmpty ? '(no output)' : truncatedBody,
    details,
  );
}
