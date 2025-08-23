// services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // معالجة الضغط على الإشعار
    if (response.payload != null) {
      // فتح الشاشة المناسبة حسب الـ payload
    }
  }

  // إشعار تذكير يومي
  Future<void> scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      0,
      'تذكير يومي 📝',
      'لا تنسَ تسجيل مصروفاتك اليوم!',
      _nextInstanceOfTime(20, 0), // 8:00 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'التذكير اليومي',
          channelDescription: 'تذكير يومي بتسجيل المصروفات',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // إشعار تجاوز الميزانية
  Future<void> showBudgetAlert(String category, double percentage) async {
    String title = percentage >= 100 
        ? '⚠️ تجاوزت الميزانية!' 
        : '📊 اقتربت من حد الميزانية';
    
    String body = percentage >= 100
        ? 'تجاوزت ميزانية "$category" بنسبة ${(percentage - 100).toStringAsFixed(0)}%'
        : 'وصلت إلى ${percentage.toStringAsFixed(0)}% من ميزانية "$category"';

    await _notifications.show(
      category.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'تنبيهات الميزانية',
          channelDescription: 'تنبيهات عند تجاوز الميزانية',
          importance: Importance.max,
          priority: Priority.high,
          color: percentage >= 100 ? const Color(0xFFD32F2F) : const Color(0xFFFF9800),
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // إشعار الالتزامات الشهرية
  Future<void> scheduleMonthlyCommitmentsReminder() async {
    await _notifications.zonedSchedule(
      1,
      '💳 موعد الالتزامات الشهرية',
      'حان وقت دفع الالتزامات الشهرية (الإيجار، الأقساط، الاشتراكات)',
      _nextInstanceOfMonthDay(1, 10, 0), // اليوم الأول من الشهر، 10:00 AM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_commitments',
          'الالتزامات الشهرية',
          channelDescription: 'تذكير بالالتزامات الشهرية',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // إشعار الأهداف المالية
  Future<void> showGoalProgress(String goalName, double progress) async {
    String emoji = progress >= 100 ? '🎉' : progress >= 75 ? '🔥' : '💪';
    String title = progress >= 100 
        ? 'مبروك! حققت هدفك' 
        : 'تقدم في الهدف المالي';
    
    await _notifications.show(
      goalName.hashCode,
      '$emoji $title',
      'وصلت إلى ${progress.toStringAsFixed(0)}% من هدف "$goalName"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goals',
          'الأهداف المالية',
          channelDescription: 'تحديثات الأهداف المالية',
          importance: Importance.high,
          priority: Priority.default,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfMonthDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      if (now.month == 12) {
        scheduledDate = tz.TZDateTime(
          tz.local,
          now.year + 1,
          1,
          day,
          hour,
          minute,
        );
      } else {
        scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month + 1,
          day,
          hour,
          minute,
        );
      }
    }
    
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}