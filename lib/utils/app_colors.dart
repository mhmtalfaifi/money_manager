import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية الجديدة
  static const Color darkBrown = Color(0xFF473D33);
  static const Color lightGreen = Color(0xFFC5D300);
  static const Color lightBeige = Color(0xFFF5F2E9);

  // الألوان المعاد تعريفها
  static const Color primary = darkBrown;
  static const Color income = lightGreen;
  static const Color commitment = Color(0xFFFFD4A3);
  
  // إزالة withOpacity من الثوابت واستبدالها بألوان ثابتة
  static const Color expense = Color(0xFF786857); // بديل عن darkBrown.withOpacity(0.7)
  static const Color dailyExpense = Color(0xFF9E8F7F); // بديل عن darkBrown.withOpacity(0.5)
  
  // ألوان الخلفية
  static const Color background = lightBeige;
  static const Color cardBackground = Colors.white;
  static const Color darkBackground = darkBrown;
  
  // ألوان النصوص
  static const Color textPrimary = darkBrown;
  static const Color textSecondary = Color(0xFF786857); // بديل عن withOpacity(0.7)
  static const Color textLight = Color(0xFF9E8F7F); // بديل عن withOpacity(0.5)
  static const Color textOnDark = Colors.white;
  
  // ألوان الحالة
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = lightGreen;
  static const Color warning = Color(0xFFFFD93D);
  static const Color info = Color(0xFF4ECDC4);
  
  // ألوان التقدم
  static const Color progressGreen = lightGreen;
  static const Color progressGray = Color(0xFFE8E8E8);
  
  // أزرار
  static const Color addButton = lightGreen;
  
  // ألوان فاتحة للخلفيات (يجب أن تكون غير const لأنها تستخدم withOpacity)
  static final Color incomeLight = lightGreen.withOpacity(0.15);
  static final Color commitmentLight = commitment.withOpacity(0.15);
  static final Color expenseLight = darkBrown.withOpacity(0.1);
  
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