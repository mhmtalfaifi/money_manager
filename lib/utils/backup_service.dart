// services/backup_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../helpers/database_helper.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ========== النسخ الاحتياطي المحلي ==========

  /// إنشاء نسخة احتياطية محلية بصيغة JSON
  Future<String?> createLocalBackup() async {
    try {
      // الحصول على جميع البيانات
      final transactions = await _db.getAllTransactions();
      final categories = <Map<String, dynamic>>[];
      final cities = await _db.getAllCities();
      final budgets = await _db.getAllBudgets();

      // الحصول على الفئات
      for (String type in ['income', 'expense', 'commitment']) {
        final typeCategories = await _db.getCategoriesByType(type);
        categories.addAll(typeCategories.map((cat) => cat.toMap()));
      }

      // إنشاء هيكل البيانات
      final backupData = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'app_name': 'مدير الأموال',
        'data': {
          'transactions': transactions.map((t) => t.toMap()).toList(),
          'categories': categories,
          'cities': cities.map((c) => c.toMap()).toList(),
          'budgets': budgets.map((b) => b.toMap()).toList(),
        },
        'statistics': {
          'total_transactions': transactions.length,
          'total_categories': categories.length,
          'total_cities': cities.length,
          'total_budgets': budgets.length,
        }
      };

      // الحصول على مجلد الوثائق
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'money_manager_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      // كتابة البيانات
      final file = File(filePath);
      await file.writeAsString(
        jsonEncode(backupData),
        encoding: utf8,
      );

      return filePath;
    } catch (e) {
      print('خطأ في إنشاء النسخة الاحتياطية: $e');
      return null;
    }
  }

  /// مشاركة النسخة الاحتياطية
  Future<bool> shareBackup() async {
    try {
      final backupPath = await createLocalBackup();
      if (backupPath == null) return false;

      await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'نسخة احتياطية من تطبيق مدير الأموال',
        subject: 'النسخة الاحتياطية - مدير الأموال',
      );

      return true;
    } catch (e) {
      print('خطأ في مشاركة النسخة الاحتياطية: $e');
      return false;
    }
  }

  // ========== استعادة البيانات ==========

  /// استيراد نسخة احتياطية من ملف
  Future<BackupRestoreResult> restoreFromFile() async {
    try {
      // اختيار الملف
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return BackupRestoreResult.cancelled();
      }

      final file = File(result.files.first.path!);
      return await _restoreFromFile(file);
    } catch (e) {
      return BackupRestoreResult.error('خطأ في اختيار الملف: $e');
    }
  }

  /// استعادة من ملف محدد
  Future<BackupRestoreResult> _restoreFromFile(File file) async {
    try {
      // قراءة الملف
      final content = await file.readAsString(encoding: utf8);
      final data = jsonDecode(content) as Map<String, dynamic>;

      // التحقق من صحة البيانات
      if (!_validateBackupData(data)) {
        return BackupRestoreResult.error('تنسيق الملف غير صحيح');
      }

      // استخراج البيانات
      final backupData = data['data'] as Map<String, dynamic>;
      
      int importedTransactions = 0;
      int importedCategories = 0;
      int importedCities = 0;
      int importedBudgets = 0;

      // استيراد الفئات
      if (backupData.containsKey('categories')) {
        final categories = backupData['categories'] as List<dynamic>;
        for (final categoryData in categories) {
          if (categoryData is Map<String, dynamic>) {
            try {
              final category = CategoryModel.fromMap(categoryData);
              await _db.insertCategory(category);
              importedCategories++;
            } catch (e) {
              // تجاهل الفئات المكررة
              continue;
            }
          }
        }
      }

      // استيراد المدن
      if (backupData.containsKey('cities')) {
        final cities = backupData['cities'] as List<dynamic>;
        for (final cityData in cities) {
          if (cityData is Map<String, dynamic>) {
            try {
              final city = CityModel.fromMap(cityData);
              await _db.insertCity(city);
              importedCities++;
            } catch (e) {
              // تجاهل المدن المكررة
              continue;
            }
          }
        }
      }

      // استيراد المعاملات
      if (backupData.containsKey('transactions')) {
        final transactions = backupData['transactions'] as List<dynamic>;
        for (final transactionData in transactions) {
          if (transactionData is Map<String, dynamic>) {
            try {
              final transaction = TransactionModel.fromMap(transactionData);
              await _db.insertTransaction(transaction);
              importedTransactions++;
            } catch (e) {
              // تجاهل المعاملات الخاطئة
              continue;
            }
          }
        }
      }

      // استيراد الميزانيات
      if (backupData.containsKey('budgets')) {
        final budgets = backupData['budgets'] as List<dynamic>;
        for (final budgetData in budgets) {
          if (budgetData is Map<String, dynamic>) {
            try {
              final budget = BudgetModel.fromMap(budgetData);
              await _db.insertBudget(budget);
              importedBudgets++;
            } catch (e) {
              // تجاهل الميزانيات الخاطئة
              continue;
            }
          }
        }
      }

      return BackupRestoreResult.success(
        importedTransactions: importedTransactions,
        importedCategories: importedCategories,
        importedCities: importedCities,
        importedBudgets: importedBudgets,
      );
    } catch (e) {
      return BackupRestoreResult.error('خطأ في استيراد البيانات: $e');
    }
  }

  /// التحقق من صحة بيانات النسخة الاحتياطية
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      // التحقق من وجود الحقول الأساسية
      if (!data.containsKey('version') || !data.containsKey('data')) {
        return false;
      }

      final backupData = data['data'] as Map<String, dynamic>?;
      if (backupData == null) return false;

      // التحقق من وجود قسم واحد على الأقل
      return backupData.containsKey('transactions') ||
             backupData.containsKey('categories') ||
             backupData.containsKey('cities') ||
             backupData.containsKey('budgets');
    } catch (e) {
      return false;
    }
  }

  // ========== إدارة الملفات ==========

  /// حذف النسخ الاحتياطية القديمة
  Future<void> cleanupOldBackups({int keepLastDays = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final cutoffDate = DateTime.now().subtract(Duration(days: keepLastDays));

      for (final file in files) {
        if (file is File && file.path.contains('money_manager_backup_')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('خطأ في تنظيف النسخ الاحتياطية: $e');
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية المحلية
  Future<List<BackupInfo>> getLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final backups = <BackupInfo>[];

      for (final file in files) {
        if (file is File && file.path.contains('money_manager_backup_')) {
          final stat = await file.stat();
          final fileName = file.path.split('/').last;
          
          backups.add(BackupInfo(
            fileName: fileName,
            filePath: file.path,
            createdAt: stat.modified,
            size: stat.size,
          ));
        }
      }

      // ترتيب حسب التاريخ (الأحدث أولاً)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      print('خطأ في الحصول على النسخ الاحتياطية: $e');
      return [];
    }
  }

  /// حذف نسخة احتياطية محددة
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('خطأ في حذف النسخة الاحتياطية: $e');
      return false;
    }
  }
}

// ========== النماذج المساعدة ==========

/// معلومات النسخة الاحتياطية
class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int size;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.size,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDate {
    return DateFormat('yyyy/MM/dd - HH:mm').format(createdAt);
  }
}

/// نتيجة عملية الاستعادة
class BackupRestoreResult {
  final bool success;
  final String? error;
  final int importedTransactions;
  final int importedCategories;
  final int importedCities;
  final int importedBudgets;
  final bool cancelled;

  BackupRestoreResult({
    required this.success,
    this.error,
    this.importedTransactions = 0,
    this.importedCategories = 0,
    this.importedCities = 0,
    this.importedBudgets = 0,
    this.cancelled = false,
  });

  factory BackupRestoreResult.success({
    int importedTransactions = 0,
    int importedCategories = 0,
    int importedCities = 0,
    int importedBudgets = 0,
  }) {
    return BackupRestoreResult(
      success: true,
      importedTransactions: importedTransactions,
      importedCategories: importedCategories,
      importedCities: importedCities,
      importedBudgets: importedBudgets,
    );
  }

  factory BackupRestoreResult.error(String error) {
    return BackupRestoreResult(
      success: false,
      error: error,
    );
  }

  factory BackupRestoreResult.cancelled() {
    return BackupRestoreResult(
      success: false,
      cancelled: true,
    );
  }

  int get totalImported =>
      importedTransactions + importedCategories + importedCities + importedBudgets;
}