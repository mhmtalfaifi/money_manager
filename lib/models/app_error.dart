// models/app_error.dart

import 'package:flutter/foundation.dart';

/// أنواع الأخطاء
enum ErrorType {
  general,
  network,
  database,
  file,
  validation,
  runtime,
}

/// نموذج الخطأ الموحد
class AppError {
  final ErrorType type;
  final String message;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final String? context; // السياق الذي حدث فيه الخطأ

  AppError({
    required this.type,
    required this.message,
    this.stackTrace,
    required this.timestamp,
    this.context,
  });

  /// إنشاء خطأ من تفاصيل Flutter Error
  factory AppError.fromFlutterError(FlutterErrorDetails details) {
    return AppError(
      type: ErrorType.runtime,
      message: details.exception.toString(),
      stackTrace: details.stack,
      timestamp: DateTime.now(),
      context: details.context?.toString(),
    );
  }

  /// إنشاء خطأ تحقق
  factory AppError.validation(String message) {
    return AppError(
      type: ErrorType.validation,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// إنشاء خطأ شبكة
  factory AppError.network(String message) {
    return AppError(
      type: ErrorType.network,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// إنشاء خطأ قاعدة بيانات
  factory AppError.database(String message) {
    return AppError(
      type: ErrorType.database,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// إنشاء خطأ ملف
  factory AppError.file(String message) {
    return AppError(
      type: ErrorType.file,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// إنشاء خطأ عام
  factory AppError.general(String message) {
    return AppError(
      type: ErrorType.general,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// إنشاء خطأ وقت التشغيل
  factory AppError.runtime(String message, [StackTrace? stackTrace]) {
    return AppError(
      type: ErrorType.runtime,
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppError{type: $type, message: $message, timestamp: $timestamp}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppError &&
        other.type == type &&
        other.message == message &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return type.hashCode ^ message.hashCode ^ timestamp.hashCode;
  }
}