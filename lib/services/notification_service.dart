// services/notification_service.dart - الإصدار المُحدث

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // تهيئة المناطق الزمنية
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      
      // إعدادات الأندرويد
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // إعدادات iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );
      
      // الإعدادات العامة
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // تهيئة المكون الإضافي
      final initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (initialized == true) {
        _initialized = true;
        
        // طلب الأذونات
        await _requestPermissions();
        
        debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
      } else {
        debugPrint('❌ فشل في تهيئة خدمة الإشعارات');
      }
      
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
    }
  }

  /// طلب الأذونات المطلوبة
  Future<bool> _requestPermissions() async {
    try {
      // للأندرويد 13+ نحتاج إذن خاص للإشعارات
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          debugPrint('⚠️ لم يتم منح إذن الإشعارات');
          return false;
        }
      }

      // طلب أذونات إضافية للإشعارات المجدولة (للأندرويد)
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      return true;
    } catch (e) {
      debugPrint('خطأ في طلب الأذونات: $e');
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('تم النقر على الإشعار: ${response.payload}');
    
    if (response.payload != null) {
      // يمكن إضافة التنقل هنا حسب نوع الإشعار
      switch (response.payload) {
        case 'daily_reminder':
          // فتح شاشة إضافة المعاملة
          break;
        case 'budget_alert':
          // فتح شاشة الميزانية
          break;
        case 'monthly_commitments':
          // فتح شاشة الالتزامات
          break;
      }
    }
  }

  /// إشعار تذكير يومي
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    if (!_initialized) {
      debugPrint('خدمة الإشعارات غير مهيأة');
      return;
    }

    try {
      await _notifications.zonedSchedule(
        0, // معرف الإشعار
        'تذكير يومي 📝',
        'لا تنسَ تسجيل مصروفاتك اليوم!',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'التذكير اليومي',
            channelDescription: 'تذكير يومي بتسجيل المصروفات',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: Color(0xFFC5D300),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: 'daily_reminder',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      debugPrint('✅ تم جدولة التذكير اليومي للساعة $hour:$minute');
    } catch (e) {
      debugPrint('خطأ في جدولة التذكير اليومي: $e');
    }
  }

  /// إشعار تجاوز الميزانية
  Future<void> showBudgetAlert(String category, double percentage) async {
    if (!_initialized) return;

    try {
      String title = percentage >= 100 
          ? '⚠️ تجاوزت الميزانية!' 
          : '📊 اقتربت من حد الميزانية';
      
      String body = percentage >= 100
          ? 'تجاوزت ميزانية "$category" بنسبة ${(percentage - 100).toStringAsFixed(0)}%'
          : 'وصلت إلى ${percentage.toStringAsFixed(0)}% من ميزانية "$category"';

      await _notifications.show(
        category.hashCode, // معرف فريد لكل فئة
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_alerts',
            'تنبيهات الميزانية',
            channelDescription: 'تنبيهات عند تجاوز الميزانية',
            importance: Importance.max,
            priority: Priority.high,
            color: percentage >= 100 
                ? const Color(0xFFD32F2F) 
                : const Color(0xFFFF9800),
            icon: '@drawable/ic_notification',
            playSound: true,
            enableVibration: true,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: 'budget_alert',
      );
      
      debugPrint('✅ تم إرسال تنبيه الميزانية لفئة: $category');
    } catch (e) {
      debugPrint('خطأ في إرسال تنبيه الميزانية: $e');
    }
  }

  /// إشعار الالتزامات الشهرية
  Future<void> scheduleMonthlyCommitmentsReminder({
    int day = 1, 
    int hour = 10, 
    int minute = 0
  }) async {
    if (!_initialized) return;

    try {
      await _notifications.zonedSchedule(
        1, // معرف الإشعار
        '💳 موعد الالتزامات الشهرية',
        'حان وقت دفع الالتزامات الشهرية (الإيجار، الأقساط، الاشتراكات)',
        _nextInstanceOfMonthDay(day, hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'monthly_commitments',
            'الالتزامات الشهرية',
            channelDescription: 'تذكير بالالتزامات الشهرية',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: Color(0xFFFF9800),
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              'لا تنس دفع الإيجار، الأقساط، والاشتراكات الشهرية'
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: 'monthly_commitments',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
      
      debugPrint('✅ تم جدولة تذكير الالتزامات الشهرية');
    } catch (e) {
      debugPrint('خطأ في جدولة تذكير الالتزامات: $e');
    }
  }

  /// إشعار تقدم الأهداف المالية
  Future<void> showGoalProgress(String goalName, double progress) async {
    if (!_initialized) return;

    try {
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
            priority: Priority.defaultPriority,
            icon: '@drawable/ic_notification',
            color: Color(0xFF4CAF50),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: 'goal_progress',
      );
      
      debugPrint('✅ تم إرسال إشعار تقدم الهدف: $goalName');
    } catch (e) {
      debugPrint('خطأ في إرسال إشعار تقدم الهدف: $e');
    }
  }

  /// إشعار فوري للاختبار
  Future<void> showTestNotification() async {
    if (!_initialized) return;

    try {
      await _notifications.show(
        999, // معرف مؤقت للاختبار
        '🔔 اختبار الإشعارات',
        'إذا رأيت هذا الإشعار، فإن النظام يعمل بشكل صحيح!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test',
            'اختبار',
            channelDescription: 'إشعارات الاختبار',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: Color(0xFFC5D300),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: 'test',
      );
      
      debugPrint('✅ تم إرسال إشعار الاختبار');
    } catch (e) {
      debugPrint('خطأ في إرسال إشعار الاختبار: $e');
    }
  }

  /// الحصول على الوقت التالي لساعة ودقيقة محددة
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

  /// الحصول على التاريخ التالي ليوم وساعة محددة من الشهر
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

  /// إلغاء إشعار محدد
  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    
    try {
      await _notifications.cancel(id);
      debugPrint('✅ تم إلغاء الإشعار $id');
    } catch (e) {
      debugPrint('خطأ في إلغاء الإشعار: $e');
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    
    try {
      await _notifications.cancelAll();
      debugPrint('✅ تم إلغاء جميع الإشعارات');
    } catch (e) {
      debugPrint('خطأ في إلغاء جميع الإشعارات: $e');
    }
  }

  /// الحصول على الإشعارات المجدولة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) return [];
    
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('خطأ في جلب الإشعارات المجدولة: $e');
      return [];
    }
  }

  /// التحقق من حالة الأذونات
  Future<bool> areNotificationsEnabled() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      debugPrint('خطأ في فحص حالة الأذونات: $e');
      return false;
    }
  }

  /// إعداد التذكيرات الافتراضية
  Future<void> setupDefaultReminders() async {
    if (!_initialized) return;

    try {
      // تذكير يومي في الساعة 8 مساءً
      await scheduleDailyReminder(hour: 20, minute: 0);
      
      // تذكير شهري في أول يوم من الشهر الساعة 10 صباحاً
      await scheduleMonthlyCommitmentsReminder(day: 1, hour: 10, minute: 0);
      
      debugPrint('✅ تم إعداد التذكيرات الافتراضية');
    } catch (e) {
      debugPrint('خطأ في إعداد التذكيرات الافتراضية: $e');
    }
  }
}