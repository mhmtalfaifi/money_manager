// utils/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية - حسب التصميم الجديد
  static const Color primary = Color(0xFF5B8DEE); // أزرق عصري
  static const Color income = Color(0xFF9FE2BF); // أخضر باستيل للدخل
  static const Color commitment = Color(0xFFFFD4A3); // برتقالي باستيل للالتزامات  
  static const Color expense = Color(0xFFB8D4F1); // أزرق فاتح للمصروفات
  static const Color dailyExpense = Color(0xFFB8D4F1); // للمصروفات اليومية
  
  // ألوان الخلفية
  static const Color background = Color(0xFFF8F9FA); // خلفية فاتحة
  static const Color cardBackground = Colors.white;
  static const Color darkBackground = Color(0xFF1A1A1A); // للشاشة الرئيسية
  
  // ألوان النصوص
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  static const Color textOnDark = Colors.white;
  
  // ألوان إضافية
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF6BCF7F);
  static const Color warning = Color(0xFFFFD93D);
  static const Color info = Color(0xFF4ECDC4);
  
  // ألوان الدائرة للرصيد المتبقي
  static const Color progressGreen = Color(0xFF6BCF7F);
  static const Color progressGray = Color(0xFFE8E8E8);
  
  // زر الإضافة
  static const Color addButton = Color(0xFF6BCF7F);
  
  // ألوان فاتحة للخلفيات
  static Color incomeLight = income.withOpacity(0.15);
  static Color commitmentLight = commitment.withOpacity(0.15);
  static Color expenseLight = expense.withOpacity(0.15);
  
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
  static const double fontSizeHuge = 36.0;
  
  // زوايا الحواف
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  static const double borderRadiusRound = 24.0;
  
  // العملة
  static const String currency = 'ريال';
  static const String currencySymbol = 'ر.س';
  
  // تنسيق الأرقام
  static String formatMoney(double amount) {
    // تنسيق الرقم بدون فاصلة عشرية إذا كان رقم صحيح
    if (amount == amount.roundToDouble()) {
      return '${amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} $currency';
    }
    return '${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} $currency';
  }
  
  static String formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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
    'بقالة',
    'مطاعم',
    'مواصلات',
    'فواتير',
    'صحة',
    'ترفيه',
    'تسوق',
    'أخرى',
  ];
  
  static const List<String> defaultCommitmentCategories = [
    'إيجار',
    'قسط سيارة',
    'قسط قرض',
    'اشتراكات',
    'تأمين',
    'فاتورة كهرباء',
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