// models/app_error.dart
enum ErrorType { database, network, validation, general, runtime, file }

class AppError {
  final ErrorType type;
  final String message;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final String? context;

  AppError({
    required this.type,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.context,
  });

  static AppError validation(String message) => AppError(
    type: ErrorType.validation,
    message: message,
    timestamp: DateTime.now(),
  );
}