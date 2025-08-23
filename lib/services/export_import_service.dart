// services/export_import_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../helpers/database_helper.dart';
import '../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  static ExportImportService get instance => _instance;
  ExportImportService._internal();

  DatabaseHelper get _db => DatabaseHelper.instance;

  // ========== تصدير إلى Excel ==========

  Future<String?> exportToExcel({
    DateTime? startDate, 
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    try {
      // الحصول على البيانات مع الفلترة
      List<TransactionModel> transactions = await _getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        cities: cities,
        transactionType: transactionType,
      );

      if (transactions.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      // إنشاء ملف Excel
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'العمليات المالية';

      // إضافة الرؤوس مع التنسيق
      _addExcelHeaders(sheet);

      // إضافة البيانات
      _addTransactionData(sheet, transactions);

      // إضافة ورقة الملخص
      _addSummarySheet(workbook, transactions);

      // إضافة ورقة الإحصائيات
      _addStatisticsSheet(workbook, transactions);

      // حفظ الملف
      final String filePath = await _saveExcelFile(workbook);
      workbook.dispose();

      return filePath;
    } catch (e) {
      throw Exception('فشل في تصدير البيانات: $e');
    }
  }

  Future<List<TransactionModel>> _getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    List<TransactionModel> transactions = await _db.getAllTransactions();

    // فلترة حسب التاريخ
    if (startDate != null || endDate != null) {
      transactions = transactions.where((t) {
        if (startDate != null && t.date.isBefore(startDate)) return false;
        if (endDate != null && t.date.isAfter(endDate.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    }

    // فلترة حسب النوع
    if (transactionType != null) {
      transactions = transactions.where((t) => t.type == transactionType).toList();
    }

    // فلترة حسب الفئات
    if (categories != null && categories.isNotEmpty) {
      transactions = transactions.where((t) => categories.contains(t.category)).toList();
    }

    // فلترة حسب المدن
    if (cities != null && cities.isNotEmpty) {
      transactions = transactions.where((t) => cities.contains(t.city)).toList();
    }

    return transactions;
  }

  void _addExcelHeaders(Worksheet sheet) {
    final headers = [
      'التاريخ', 'الوقت', 'النوع', 'الوصف', 'المبلغ', 
      'المدينة', 'الفئة', 'متكررة', 'ملاحظات'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      final Range headerCell = sheet.getRangeByIndex(1, i + 1);
      headerCell.setText(headers[i]);
      headerCell.cellStyle.backColor = '#4CAF50';
      headerCell.cellStyle.fontColor = '#FFFFFF';
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.fontSize = 12;
      headerCell.autoFitColumns();
    }
  }

  void _addTransactionData(Worksheet sheet, List<TransactionModel> transactions) {
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final int row = i + 2;

      sheet.getRangeByIndex(row, 1).setText(DateFormat('yyyy-MM-dd').format(transaction.date));
      sheet.getRangeByIndex(row, 2).setText(DateFormat('HH:mm').format(transaction.date));
      sheet.getRangeByIndex(row, 3).setText(_getTypeLabel(transaction.type));
      sheet.getRangeByIndex(row, 4).setText(transaction.description);
      sheet.getRangeByIndex(row, 5).setNumber(transaction.amount);
      sheet.getRangeByIndex(row, 6).setText(transaction.city);
      sheet.getRangeByIndex(row, 7).setText(transaction.category);
      sheet.getRangeByIndex(row, 8).setText(transaction.isRecurring ? 'نعم' : 'لا');
      sheet.getRangeByIndex(row, 9).setText(transaction.notes ?? '');

      // تلوين الصفوف حسب النوع
      final String color = _getTypeColor(transaction.type);
      for (int col = 1; col <= 9; col++) {
        sheet.getRangeByIndex(row, col).cellStyle.backColor = color;
      }
    }
  }

  void _addSummarySheet(Workbook workbook, List<TransactionModel> transactions) {
    final Worksheet summarySheet = workbook.worksheets.addWithName('الملخص');

    // حساب الإجماليات
    final summary = _calculateSummary(transactions);

    // كتابة الملخص
    summarySheet.getRangeByIndex(1, 1).setText('الملخص المالي');
    summarySheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    summarySheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;

    final List<List<dynamic>> summaryData = [
      ['إجمالي الدخل', summary['totalIncome']],
      ['إجمالي المصروفات', summary['totalExpenses']],
      ['إجمالي الالتزامات', summary['totalCommitments']],
      ['الرصيد المتبقي', summary['balance']],
      ['عدد العمليات', transactions.length],
      ['معدل الادخار %', summary['savingsRate']],
    ];

    for (int i = 0; i < summaryData.length; i++) {
      summarySheet.getRangeByIndex(i + 3, 2)
        .setText(summaryData[i][1].toString());
    }

    // إضافة ملخص الفئات
    summarySheet.getRangeByIndex(10, 1).setText('ملخص الفئات');
    summarySheet.getRangeByIndex(10, 1).cellStyle.bold = true;
    
    final categoryTotals = _getCategoryTotals(transactions);
    int rowIndex = 11;
    categoryTotals.forEach((category, amount) {
      summarySheet.getRangeByIndex(rowIndex, 1).setText(category);
      summarySheet.getRangeByIndex(rowIndex, 2).setText(amount.toString());
      rowIndex++;
    });
  }

  void _addStatisticsSheet(Workbook workbook, List<TransactionModel> transactions) {
    final Worksheet statsSheet = workbook.worksheets.addWithName('الإحصائيات');
    
    statsSheet.getRangeByIndex(1, 1).setText('الإحصائيات التفصيلية');
    statsSheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    statsSheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;

    // إحصائيات الفترة
    final dateRange = _getDateRange(transactions);
    statsSheet.getRangeByIndex(3, 1).setText('فترة البيانات');
    statsSheet.getRangeByIndex(3, 2).setText('${DateFormat('yyyy-MM-dd').format(dateRange['start']!)} إلى ${DateFormat('yyyy-MM-dd').format(dateRange['end']!)}');

    // أكثر الفئات إنفاقاً
    final topCategories = _getTopCategories(transactions, limit: 5);
    statsSheet.getRangeByIndex(5, 1).setText('أكثر 5 فئات إنفاقاً');
    statsSheet.getRangeByIndex(5, 1).cellStyle.bold = true;
    
    for (int i = 0; i < topCategories.length; i++) {
      statsSheet.getRangeByIndex(6 + i, 1).setText(topCategories[i]['category']);
      statsSheet.getRangeByIndex(6 + i, 2).setText(topCategories[i]['amount'].toString());
    }

    // أكثر المدن إنفاقاً
    final topCities = _getTopCities(transactions, limit: 5);
    statsSheet.getRangeByIndex(12, 1).setText('أكثر 5 مدن إنفاقاً');
    statsSheet.getRangeByIndex(12, 1).cellStyle.bold = true;
    
    for (int i = 0; i < topCities.length; i++) {
      statsSheet.getRangeByIndex(13 + i, 1).setText(topCities[i]['city']);
      statsSheet.getRangeByIndex(13 + i, 2).setText(topCities[i]['amount'].toString());
    }
  }

  Map<String, dynamic> _calculateSummary(List<TransactionModel> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalCommitments = 0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case 'income':
          totalIncome += transaction.amount;
          break;
        case 'expense':
          totalExpenses += transaction.amount;
          break;
        case 'commitment':
          totalCommitments += transaction.amount;
          break;
      }
    }

    final balance = totalIncome - totalExpenses - totalCommitments;
    final savingsRate = totalIncome > 0 ? (balance / totalIncome * 100) : 0;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalCommitments': totalCommitments,
      'balance': balance,
      'savingsRate': savingsRate.toStringAsFixed(1),
    };
  }

  Map<String, double> _getCategoryTotals(List<TransactionModel> transactions) {
    final Map<String, double> categoryTotals = {};
    
    for (final transaction in transactions) {
      if (transaction.type == 'expense' || transaction.type == 'commitment') {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return Map.fromEntries(
      categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  Map<String, DateTime> _getDateRange(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      final now = DateTime.now();
      return {'start': now, 'end': now};
    }
    
    DateTime earliest = transactions.first.date;
    DateTime latest = transactions.first.date;
    
    for (final transaction in transactions) {
      if (transaction.date.isBefore(earliest)) earliest = transaction.date;
      if (transaction.date.isAfter(latest)) latest = transaction.date;
    }
    
    return {'start': earliest, 'end': latest};
  }

  List<Map<String, dynamic>> _getTopCategories(List<TransactionModel> transactions, {int limit = 5}) {
    final categoryTotals = _getCategoryTotals(transactions);
    return categoryTotals.entries
        .take(limit)
        .map((e) => {'category': e.key, 'amount': e.value})
        .toList();
  }

  List<Map<String, dynamic>> _getTopCities(List<TransactionModel> transactions, {int limit = 5}) {
    final Map<String, double> cityTotals = {};
    
    for (final transaction in transactions) {
      if (transaction.type == 'expense' || transaction.type == 'commitment') {
        cityTotals[transaction.city] = 
            (cityTotals[transaction.city] ?? 0) + transaction.amount;
      }
    }
    
    final sortedCities = Map.fromEntries(
      cityTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
    
    return sortedCities.entries
        .take(limit)
        .map((e) => {'city': e.key, 'amount': e.value})
        .toList();
  }

  Future<String> _saveExcelFile(Workbook workbook) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String filePath = '${directory.path}/money_manager_export_$timestamp.xlsx';
    
    final List<int> bytes = workbook.saveAsStream();
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    
    return filePath;
  }

  String _getTypeLabel(String type) {
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

  String _getTypeColor(String type) {
    switch (type) {
      case 'income':
        return '#E8F5E8';
      case 'expense':
        return '#E3F2FD';
      case 'commitment':
        return '#FFF3E0';
      default:
        return '#FFFFFF';
    }
  }

  // ========== مشاركة ملف Excel ==========

  Future<void> shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'تقرير مالي من تطبيق مدير الأموال',
        subject: 'التقرير المالي - مدير الأموال',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة الملف: $e');
    }
  }

  // ========== تصدير إلى JSON ==========

  Future<String?> exportToJson({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    try {
      final List<TransactionModel> transactions = await _getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        cities: cities,
        transactionType: transactionType,
      );

      if (transactions.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      final exportData = {
        'export_info': {
          'app_name': 'مدير الأموال',
          'export_date': DateTime.now().toIso8601String(),
          'version': '1.0',
          'filters': {
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'categories': categories,
            'cities': cities,
            'transaction_type': transactionType,
          }
        },
        'summary': _calculateSummary(transactions),
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'statistics': {
          'total_count': transactions.length,
          'date_range': _getDateRange(transactions),
          'top_categories': _getTopCategories(transactions),
          'top_cities': _getTopCities(transactions),
        }
      };

      final Directory directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '${directory.path}/money_manager_export_$timestamp.json';
      
      final File file = File(filePath);
      await file.writeAsString(
        jsonEncode(exportData),
        encoding: utf8,
      );

      return filePath;
    } catch (e) {
      throw Exception('فشل في إنشاء التصدير: $e');
    }
  }

  // ========== استيراد من JSON ==========

  Future<ImportResult> importFromJson() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.cancelled();
      }

      final File file = File(result.files.first.path!);
      final String content = await file.readAsString(encoding: utf8);
      final dynamic data = jsonDecode(content);

      if (data is! Map<String, dynamic>) {
        return ImportResult.error('تنسيق الملف غير صحيح');
      }

      return await _processJsonImport(data);
    } catch (e) {
      return ImportResult.error('فشل في استيراد البيانات: $e');
    }
  }

  Future<ImportResult> _processJsonImport(Map<String, dynamic> data) async {
    try {
      int importedCount = 0;
      int skippedCount = 0;

      // استيراد المعاملات
      if (data.containsKey('transactions')) {
        final List<dynamic> transactionsData = data['transactions'];
        
        for (final transactionData in transactionsData) {
          if (transactionData is Map<String, dynamic>) {
            try {
              final transaction = TransactionModel.fromMap(transactionData);
              await _db.insertTransaction(transaction);
              importedCount++;
            } catch (e) {
              skippedCount++;
              continue;
            }
          }
        }
      }

      return ImportResult.success(
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      return ImportResult.error('خطأ في معالجة البيانات: $e');
    }
  }

  // ========== استيراد من Excel ==========

  Future<ImportResult> importFromExcel() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.cancelled();
      }

      final File file = File(result.files.first.path!);
      final List<int> bytes = await file.readAsBytes();
      final Workbook workbook = Workbook(bytes);
      final Worksheet sheet = workbook.worksheets[0];

      if (sheet.rows.isEmpty) {
        workbook.dispose();
        return ImportResult.error('الورقة فارغة');
      }

      int importedCount = 0;
      int skippedCount = 0;
      final List<Row> rows = sheet.rows;

      // تخطي صف الرؤوس
      for (int i = 1; i < rows.length; i++) {
        final Row row = rows[i];
        if (row.cells.length < 5) {
          skippedCount++;
          continue;
        }

        try {
          final TransactionModel? transaction = _parseExcelRow(row.cells);
          if (transaction != null) {
            await _db.insertTransaction(transaction);
            importedCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          skippedCount++;
          continue;
        }
      }

      workbook.dispose();
      return ImportResult.success(
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      return ImportResult.error('فشل في استيراد البيانات: $e');
    }
  }

  TransactionModel? _parseExcelRow(List<Cell> cells) {
    try {
      final String? dateStr = cells[0].value?.toString();
      final String? timeStr = cells[1].value?.toString();
      final String? typeStr = cells[2].value?.toString();
      final String? description = cells[3].value?.toString();
      final String? amountStr = cells[4].value?.toString();
      final String? city = cells.length > 5 ? cells[5].value?.toString() : 'غير محدد';

      if (dateStr == null || typeStr == null || description == null || amountStr == null) {
        return null;
      }

      // تحويل التاريخ والوقت
      final DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
      DateTime finalDate = date;
      
      if (timeStr != null && timeStr.isNotEmpty) {
        try {
          final DateTime time = DateFormat('HH:mm').parse(timeStr);
          finalDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        } catch (e) {
          finalDate = date;
        }
      }

      // تحويل النوع
      String? type;
      switch (typeStr) {
        case 'دخل':
          type = 'income';
          break;
        case 'مصروف':
          type = 'expense';
          break;
        case 'التزام':
          type = 'commitment';
          break;
        default:
          return null;
      }

      // تحويل المبلغ
      final double? amount = double.tryParse(amountStr.replaceAll(',', ''));
      if (amount == null || amount <= 0) return null;

      // الفئة
      String category = 'أخرى';
      if (cells.length > 6 && cells[6].value != null) {
        category = cells[6].value.toString();
      }

      // المتكررة
      bool isRecurring = false;
      if (cells.length > 7 && cells[7].value != null) {
        isRecurring = cells[7].value.toString().toLowerCase() == 'نعم';
      }

      // الملاحظات
      String? notes;
      if (cells.length > 8 && cells[8].value != null) {
        notes = cells[8].value.toString();
        if (notes!.isEmpty) notes = null;
      }

      return TransactionModel(
        type: type,
        description: description,
        amount: amount,
        category: category,
        city: city ?? 'غير محدد',
        date: finalDate,
        isRecurring: isRecurring,
        notes: notes,
      );
    } catch (e) {
      return null;
    }
  }

  // ========== حذف الملفات المؤقتة ==========

  Future<void> cleanupTempFiles() async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();
      
      for (final FileSystemEntity file in files) {
        if (file is File && 
            (file.path.contains('money_manager_export_') || 
             file.path.contains('money_manager_backup_'))) {
          try {
            final stat = await file.stat();
            final Duration age = DateTime.now().difference(stat.modified);
            if (age.inDays > 7) {
              await file.delete();
            }
          } catch (e) {
            // تجاهل أخطاء الحذف
          }
        }
      }
    } catch (e) {
      // تجاهل أخطاء التنظيف
    }
  }
}

// ========== نتيجة الاستيراد ==========

class ImportResult {
  final bool success;
  final String? error;
  final int importedCount;
  final int skippedCount;
  final bool cancelled;

  ImportResult({
    required this.success,
    this.error,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.cancelled = false,
  });

  factory ImportResult.success({
    int importedCount = 0,
    int skippedCount = 0,
  }) {
    return ImportResult(
      success: true,
      importedCount: importedCount,
      skippedCount: skippedCount,
    );
  }

  factory ImportResult.error(String error) {
    return ImportResult(
      success: false,
      error: error,
    );
  }

  factory ImportResult.cancelled() {
    return ImportResult(
      success: false,
      cancelled: true,
    );
  }
}Index(i + 3, 1)
        ..setText(summaryData[i][0].toString())
        ..cellStyle.bold = true;
      
      summarySheet.getRangeBy