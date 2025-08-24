// services/error_handler_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_error.dart'; // استخدام التعريف الموحد

/// خدمة معالجة الأخطاء الشاملة
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  // سجل الأخطاء
  final List<AppError> _errorLog = [];
  final int _maxLogSize = 100;

  /// تهيئة معالج الأخطاء العام
  void initialize() {
    // معالجة أخطاء Flutter غير المتوقعة
    FlutterError.onError = (FlutterErrorDetails details) {
      _logError(AppError.fromFlutterError(details));
      
      // في وضع التطوير، اعرض الخطأ
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // معالجة أخطاء Dart غير المتوقعة
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(AppError.runtime(error.toString(), stack));
      return true;
    };
  }

  /// تسجيل خطأ جديد
  void logError(AppError error) {
    _logError(error);
  }

  /// تسجيل خطأ بسيط
  void logSimpleError(String message, {ErrorType? type}) {
    _logError(AppError(
      type: type ?? ErrorType.general,
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  void _logError(AppError error) {
    // إضافة للسجل
    _errorLog.add(error);
    
    // تنظيف السجل إذا تجاوز الحد الأقصى
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeAt(0);
    }

    // طباعة في وضع التطوير
    if (kDebugMode) {
      debugPrint('🚨 خطأ: ${error.message}');
      if (error.stackTrace != null) {
        debugPrint('📍 Stack: ${error.stackTrace}');
      }
    }
  }

  /// عرض رسالة خطأ للمستخدم
  void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: _getErrorColor(error.type),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _getErrorTitle(error.type),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          _getUserFriendlyMessage(error.message),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
          if (error.type == ErrorType.network || error.type == ErrorType.database)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // يمكن إضافة منطق إعادة المحاولة هنا
              },
              child: const Text('إعادة المحاولة'),
            ),
        ],
      ),
    );
  }

  /// عرض رسالة خطأ بسيطة
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إخفاء',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// التعامل مع أخطاء قاعدة البيانات
  Future<T?> handleDatabaseOperation<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showError = true,
    BuildContext? context,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final error = AppError.database(e.toString());
      
      logError(error);
      
      if (showError && context != null) {
        showErrorSnackBar(context, errorMessage ?? 'حدث خطأ في قاعدة البيانات');
      }
      
      return null;
    }
  }

  /// التعامل مع أخطاء الشبكة
  Future<T?> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showError = true,
    BuildContext? context,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final error = AppError.network(e.toString());
      
      logError(error);
      
      if (showError && context != null) {
        showErrorSnackBar(context, errorMessage ?? 'تحقق من الاتصال بالإنترنت');
      }
      
      return null;
    }
  }

  /// التعامل مع أخطاء الملفات
  Future<T?> handleFileOperation<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showError = true,
    BuildContext? context,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final error = AppError.file(e.toString());
      
      logError(error);
      
      if (showError && context != null) {
        showErrorSnackBar(context, errorMessage ?? 'خطأ في التعامل مع الملف');
      }
      
      return null;
    }
  }

  String _getUserFriendlyMessage(String originalMessage) {
    // تحويل رسائل الأخطاء التقنية إلى رسائل مفهومة للمستخدم
    final Map<String, String> messageMap = {
      'No such file or directory': 'الملف غير موجود',
      'Permission denied': 'ليس لديك صلاحية للوصول',
      'Network error': 'خطأ في الشبكة، تحقق من الاتصال',
      'Database error': 'خطأ في قاعدة البيانات',
      'Invalid format': 'تنسيق غير صحيح',
      'Out of memory': 'نفدت الذاكرة، أغلق بعض التطبيقات',
    };

    for (final entry in messageMap.entries) {
      if (originalMessage.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return originalMessage.length > 100 
        ? '${originalMessage.substring(0, 100)}...'
        : originalMessage;
  }

  String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'خطأ في الشبكة';
      case ErrorType.database:
        return 'خطأ في البيانات';
      case ErrorType.file:
        return 'خطأ في الملف';
      case ErrorType.validation:
        return 'خطأ في المدخلات';
      case ErrorType.runtime:
        return 'خطأ في التشغيل';
      case ErrorType.general:
      default:
        return 'خطأ';
    }
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.file:
        return Icons.folder_off;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.runtime:
        return Icons.bug_report;
      case ErrorType.general:
      default:
        return Icons.error;
    }
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.database:
        return Colors.purple;
      case ErrorType.file:
        return Colors.blue;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.runtime:
        return Colors.red;
      case ErrorType.general:
      default:
        return Colors.grey;
    }
  }

  /// الحصول على سجل الأخطاء
  List<AppError> get errorLog => List.unmodifiable(_errorLog);

  /// مسح سجل الأخطاء
  void clearErrorLog() {
    _errorLog.clear();
  }

  /// الحصول على أحدث الأخطاء
  List<AppError> getRecentErrors({int limit = 10}) {
    return _errorLog.reversed.take(limit).toList();
  }
}