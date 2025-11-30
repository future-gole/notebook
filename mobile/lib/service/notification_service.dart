import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/util/logger_service.dart';
import 'package:pocketmind/util/app_config.dart';
import 'dart:io';

final notificationService = NotificationService();
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return notificationService;
});

class NotificationService {
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    String? timeZoneName;
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      timeZoneName = timezoneInfo.identifier;
      log.i('NotificationService', '获取到系统时区: $timeZoneName');
    } catch (e) {
      log.e('NotificationService', '获取系统时区失败: $e');
    }

    try {
      if (timeZoneName != null) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } else {
        throw Exception('TimeZone name is null');
      }
    } catch (e) {
      log.w(
        'NotificationService',
        '无法设置本地时区 ($timeZoneName), 尝试默认使用北京时间 (Asia/Shanghai)',
      );
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
        log.i('NotificationService', '已切换到北京时间');
      } catch (e2) {
        log.e('NotificationService', '设置北京时间失败, 降级使用 UTC: $e2');
        tz.setLocalLocation(tz.UTC);
      }
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/launcher_icon');

    final fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse notificationResponse) async {
            // Handle notification tap
          },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            fln.MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                fln.AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();

      // 检查并请求精确闹钟权限
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // 1. 将输入的 DateTime (本地时间) 转换为 tz.local 时区下的 TZDateTime
    tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final config = AppConfig();
    // 根据配置设置通知强度
    fln.Importance importance;
    fln.Priority priority;

    switch (config.notificationIntensity) {
      case 0: // 低
        importance = fln.Importance.low;
        priority = fln.Priority.low;
        break;
      case 1: // 中
        importance = fln.Importance.defaultImportance;
        priority = fln.Priority.defaultPriority;
        break;
      case 2: // 高
      default:
        importance = fln.Importance.max;
        priority = fln.Priority.high;
        break;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'reminder_channel_v7', // 更新 Channel ID
            'Reminders',
            channelDescription: 'Channel for note reminders',
            importance: importance,
            priority: priority,
          ),
          iOS: fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: fln.InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: config.highPrecisionNotification
            ? fln.AndroidScheduleMode.alarmClock
            : fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );
      log.i('NotificationService', '通知调度成功');
    } catch (e) {
      log.e('NotificationService', '调度通知失败: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
