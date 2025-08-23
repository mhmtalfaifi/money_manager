// utils/app_constants.dart

import 'package:intl/intl.dart';

class AppConstants {
  // معلومات التطبيق
  static const String appName = 'مدير الأموال';
  static const String appVersion = '1.0.0';
  
  // العملة
  static const String currency = 'ريال';
  static const String currencySymbol = 'ر.س';
  
  // فئات الدخل الافتراضية
  static const List<String> defaultIncomeCategories = [
    'الراتب',
    'عمل إضافي',
    'استثمار',
    'هدية',
    'بيع',
    'أخرى',
  ];
  
  // فئات المصروفات الافتراضية  
  static const List<String> defaultExpenseCategories = [
    'بقالة',
    'مطاعم',
    'مواصلات',
    'فواتير',
    'فاتورة كهرباء',
    'فاتورة ماء',
    'فاتورة انترنت',
    'صحة',
    'ترفيه',
    'تسوق',
    'ملابس',
    'تعليم',
    'سفر',
    'صيانة',
    'أخرى',
  ];
  
  // فئات الالتزامات الافتراضية
  static const List<String> defaultCommitmentCategories = [
    'إيجار',
    'قسط سيارة',
    'قسط قرض',
    'اشتراكات',
    'تأمين',
    'أخرى',
  ];
  
  // المدن الافتراضية
  static const List<String> defaultCities = [
    'الرياض',
    'جدة',
    'الدمام',
    'مكة المكرمة',
    'المدينة المنورة',
    'الطائف',
    'تبوك',
    'بريدة',
    'الخبر',
    'أبها',
    'نجران',
    'حائل',
    'الجوف',
    'عرعر',
    'جازان',
    'الباحة',
    'القصيم',
    'الأحساء',
    'ينبع',
    'خميس مشيط',
  ];
  
  // تنسيق الأرقام
  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'ar_SA');
    return formatter.format(number);
  }
  
  // تنسيق المبالغ
  static String formatMoney(double amount) {
    return '${formatNumber(amount)} $currency';
  }
  
  // تنسيق المبالغ مع الرمز
  static String formatMoneyWithSymbol(double amount) {
    return '${formatNumber(amount)} $currencySymbol';
  }
  
  // تنسيق المبلغ المختصر
  static String formatCompactMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}م $currency';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}ك $currency';
    } else {
      return formatMoney(amount);
    }
  }
  
  // تنسيق التاريخ
  static String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ar_SA').format(date);
  }
  
  // تنسيق التاريخ المختصر
  static String formatShortDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }
  
  // تنسيق الوقت
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a', 'ar_SA').format(date);
  }
  
  // تنسيق التاريخ والوقت
  static String formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy - h:mm a', 'ar_SA').format(date);
  }
  
  // تنسيق الشهر والسنة
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'ar_SA').format(date);
  }
  
  // الحصول على اسم اليوم
  static String getDayName(DateTime date) {
    return DateFormat('EEEE', 'ar_SA').format(date);
  }
  
  // الحصول على اسم الشهر
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM', 'ar_SA').format(date);
  }
  
  // تحويل النوع إلى نص
  static String getTypeText(String type) {
    switch (type) {
      case 'income':
        return 'دخل';
      case 'expense':
        return 'مصروف';
      case 'commitment':
        return 'التزام';
      default:
        return type;
    }
  }
  
  // الحصول على لون النوع
  static String getTypeColor(String type) {
    switch (type) {
      case 'income':
        return '#4CAF50';
      case 'expense':
        return '#F44336';
      case 'commitment':
        return '#FF9800';
      default:
        return '#9E9E9E';
    }
  }
  
  // الحد الأدنى للمبلغ
  static const double minAmount = 0.01;
  
  // الحد الأقصى للمبلغ
  static const double maxAmount = 999999999.99;
  
  // إعدادات التطبيق
  static const Map<String, dynamic> defaultSettings = {
    'currency': currency,
    'language': 'ar',
    'notifications': true,
    'backupReminder': true,
    'biometric': false,
    'autoBackup': false,
    'theme': 'light',
    'budgetAlerts': true,
    'monthlyReports': true,
  };
  
  // أنماط التكرار
  static const Map<String, String> recurringPatterns = {
    'daily': 'يومي',
    'weekly': 'أسبوعي',
    'monthly': 'شهري',
    'yearly': 'سنوي',
  };
  
  // فترات الميزانية
  static const Map<String, String> budgetPeriods = {
    'monthly': 'شهري',
    'quarterly': 'ربع سنوي',
    'yearly': 'سنوي',
  };
  
  // أنواع التقارير
  static const Map<String, String> reportTypes = {
    'summary': 'ملخص',
    'detailed': 'تفصيلي',
    'comparison': 'مقارنة',
    'trends': 'اتجاهات',
  };
  
  // فترات التقارير
  static const Map<String, String> reportPeriods = {
    'week': 'أسبوع',
    'month': 'شهر',
    'quarter': 'ربع سنة',
    'year': 'سنة',
    'custom': 'مخصص',
  };
  
  // رسائل التحقق
  static const Map<String, String> validationMessages = {
    'required': 'هذا الحقل مطلوب',
    'invalidAmount': 'المبلغ غير صحيح',
    'invalidDate': 'التاريخ غير صحيح',
    'invalidEmail': 'البريد الإلكتروني غير صحيح',
    'invalidPhone': 'رقم الهاتف غير صحيح',
    'minLength': 'يجب أن يكون الحد الأدنى {min} أحرف',
    'maxLength': 'يجب أن لا يتجاوز {max} حرف',
    'minAmount': 'المبلغ يجب أن يكون أكبر من ${minAmount}',
    'maxAmount': 'المبلغ يجب أن لا يتجاوز ${maxAmount}',
  };
  
  // الرسائل العامة
  static const Map<String, String> messages = {
    'success': 'تم بنجاح',
    'error': 'حدث خطأ',
    'loading': 'جاري التحميل...',
    'saving': 'جاري الحفظ...',
    'deleting': 'جاري الحذف...',
    'noData': 'لا توجد بيانات',
    'noInternet': 'لا يوجد اتصال بالإنترنت',
    'confirmDelete': 'هل أنت متأكد من الحذف؟',
    'confirmAction': 'هل أنت متأكد من هذا الإجراء؟',
    'cancel': 'إلغاء',
    'confirm': 'تأكيد',
    'retry': 'إعادة المحاولة',
    'close': 'إغلاق',
    'save': 'حفظ',
    'edit': 'تعديل',
    'delete': 'حذف',
    'add': 'إضافة',
    'search': 'بحث',
    'filter': 'تصفية',
    'sort': 'ترتيب',
    'export': 'تصدير',
    'import': 'استيراد',
    'backup': 'نسخ احتياطي',
    'restore': 'استرجاع',
    'settings': 'الإعدادات',
    'help': 'المساعدة',
    'about': 'حول التطبيق',
  };
  
  // أيقونات الفئات
  static const Map<String, String> categoryIcons = {
    // دخل
    'الراتب': '💰',
    'عمل إضافي': '💼',
    'استثمار': '📈',
    'هدية': '🎁',
    'بيع': '🏪',
    
    // مصروفات
    'بقالة': '🛒',
    'مطاعم': '🍽️',
    'مواصلات': '🚗',
    'فواتير': '📄',
    'صحة': '🏥',
    'ترفيه': '🎬',
    'تسوق': '🛍️',
    'ملابس': '👕',
    'تعليم': '📚',
    'سفر': '✈️',
    'صيانة': '🔧',
    
    // التزامات
    'إيجار': '🏠',
    'قسط سيارة': '🚙',
    'قسط قرض': '🏛️',
    'اشتراكات': '📱',
    'تأمين': '🛡️',
    
    // افتراضي
    'أخرى': '📝',
  };
  
  // ألوان الفئات
  static const Map<String, String> categoryColors = {
    'income': '#4CAF50',
    'expense': '#F44336',
    'commitment': '#FF9800',
  };
  
  // حدود الإشعارات
  static const double budgetWarningThreshold = 0.8; // 80%
  static const double budgetCriticalThreshold = 1.0; // 100%
  
  // إعدادات الأمان
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const int sessionTimeoutMinutes = 30;
  
  // إعدادات النسخ الاحتياطي
  static const int autoBackupDays = 7;
  static const int maxBackupFiles = 10;
  
  // التحقق من صحة البيانات
  static bool isValidAmount(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }
  
  static bool isValidDescription(String description) {
    return description.trim().length >= 2 && description.trim().length <= 100;
  }
  
  static bool isValidCategoryName(String name) {
    return name.trim().length >= 2 && name.trim().length <= 50;
  }
  
  static bool isValidCityName(String name) {
    return name.trim().length >= 2 && name.trim().length <= 50;
  }
}