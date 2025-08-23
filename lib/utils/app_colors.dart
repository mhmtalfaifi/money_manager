import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية - محدثة حسب الصورة
  static const Color primary = Color(0xFF4CAF50); // أخضر فاتح
  static const Color income = Color(0xFF81C784); // أخضر فاتح للدخل
  static const Color commitment = Color(0xFFFFB74D); // برتقالي فاتح للالتزامات
  static const Color expense = Color(0xFF90CAF9); // أزرق فاتح للمصروفات
  
  // ألوان الخلفية
  static const Color background = Color(0xFFFAFAFA); // خلفية فاتحة جداً
  static const Color cardBackground = Colors.white;
  
  // ألوان النصوص
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  
  // ألوان إضافية
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF42A5F5);
  
  // باقي الكود يبقى كما هو...
  static Color incomeLight = income.withOpacity(0.1);
  static Color commitmentLight = commitment.withOpacity(0.1);
  static Color expenseLight = expense.withOpacity(0.1);
  
  static Color getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return income;
      case 'commitment':
        return commitment;
      case 'expense':
        return expense;
      default:
        return textSecondary;
    }
  }
  
  static Color getTransactionLightColor(String type) {
    switch (type) {
      case 'income':
        return incomeLight;
      case 'commitment':
        return commitmentLight;
      case 'expense':
        return expenseLight;
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }
  
  static IconData getTransactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward_rounded;
      case 'commitment':
        return Icons.event_repeat_rounded;
      case 'expense':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }
}

// ثوابت التنسيق
class AppConstants {
  
  // المسافات
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // أحجام الخطوط
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  
  // زوايا الحواف
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  
  // العملة
  static const String currency = 'ريال';
  static const String currencySymbol = 'ر.س';
  
  // تنسيق الأرقام
  static String formatMoney(double amount) {
    return '${amount.toStringAsFixed(2)} $currencySymbol';
  }
  
  // الفئات الافتراضية
  static const List<String> defaultIncomeCategories = [
    'الراتب',
    'عمل إضافي',
    'استثمار',
    'هدية',
    'أخرى',
  ];
  
  static const List<String> defaultExpenseCategories = [
    'طعام ومشروبات',
    'تسوق',
    'مواصلات',
    'فواتير',
    'صحة',
    'ترفيه',
    'تعليم',
    'أخرى',
  ];
  
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
    'مكة المكرمة',
    'المدينة المنورة',
    'الدمام',
    'الخبر',
    'أخرى',
  ];
}
