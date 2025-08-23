// services/export_import_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../helpers/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'pdf_export_service.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:csv/csv.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  static ExportImportService get instance => _instance;
  ExportImportService._internal();

  DatabaseHelper get _db => DatabaseHelper.instance;

  // ========== Export to Excel ==========

  Future<String?> exportToExcel({
    DateTime? startDate, 
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    try {
      // Get filtered data
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

      // Create Excel file
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'العمليات المالية';

      // Add headers with formatting
      _addExcelHeaders(sheet);

      // Add data
      _addTransactionData(sheet, transactions);

      // Add summary sheet
      _addSummarySheet(workbook, transactions);

      // Add statistics sheet
      _addStatisticsSheet(workbook, transactions);

      // Save file
      final String filePath = await _saveExcelFile(workbook);
      workbook.dispose();

      return filePath;
    } catch (e) {
      throw Exception('فشل في تصدير البيانات: $e');
    }
  }

  void _addExcelHeaders(xlsio.Worksheet sheet) {
    final headers = [
      'التاريخ', 'الوقت', 'النوع', 'الوصف', 'المبلغ', 
      'المدينة', 'الفئة', 'متكررة', 'ملاحظات'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      final xlsio.Range headerCell = sheet.getRangeByIndex(1, i + 1);
      headerCell.setText(headers[i]);
      headerCell.cellStyle.backColor = '#4CAF50';
      headerCell.cellStyle.fontColor = '#FFFFFF';
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.fontSize = 12;
    }
    sheet.autoFitColumn(1);
  }

  void _addTransactionData(xlsio.Worksheet sheet, List<TransactionModel> transactions) {
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final row = i + 2;
      
      sheet.getRangeByIndex(row, 1).setText(DateFormat('yyyy/MM/dd').format(transaction.date));
      sheet.getRangeByIndex(row, 2).setText(DateFormat('HH:mm').format(transaction.date));
      sheet.getRangeByIndex(row, 3).setText(_getTypeLabel(transaction.type));
      sheet.getRangeByIndex(row, 4).setText(transaction.description);
      sheet.getRangeByIndex(row, 5).setNumber(transaction.amount);
      sheet.getRangeByIndex(row, 6).setText(transaction.city);
      sheet.getRangeByIndex(row, 7).setText(transaction.category);
      sheet.getRangeByIndex(row, 8).setText(transaction.isRecurring ? 'نعم' : 'لا');
      sheet.getRangeByIndex(row, 9).setText(transaction.notes ?? '');
    }
    
    // Auto-fit columns
    for (int i = 1; i <= 9; i++) {
      sheet.autoFitColumn(i);
    }
  }

  void _addSummarySheet(xlsio.Workbook workbook, List<TransactionModel> transactions) {
    final summarySheet = workbook.worksheets.add();
    summarySheet.name = 'الملخص';
    
    // Headers
    summarySheet.getRangeByIndex(1, 1).setText('البيان');
    summarySheet.getRangeByIndex(1, 2).setText('القيمة');
    
    // Data
    final summary = _calculateSummary(transactions);
    int row = 2;
    
    summarySheet.getRangeByIndex(row++, 1).setText('إجمالي الدخل');
    summarySheet.getRangeByIndex(row-1, 2).setText(summary['totalIncome'].toString());
    
    summarySheet.getRangeByIndex(row++, 1).setText('إجمالي المصروفات');
    summarySheet.getRangeByIndex(row-1, 2).setText(summary['totalExpenses'].toString());
    
    summarySheet.getRangeByIndex(row++, 1).setText('إجمالي الالتزامات');
    summarySheet.getRangeByIndex(row-1, 2).setText(summary['totalCommitments'].toString());
    
    summarySheet.getRangeByIndex(row++, 1).setText('الرصيد المتبقي');
    summarySheet.getRangeByIndex(row-1, 2).setText(summary['balance'].toString());
    
    // Format headers
    for (int i = 1; i <= 2; i++) {
      final headerCell = summarySheet.getRangeByIndex(1, i);
      headerCell.cellStyle.backColor = '#2196F3';
      headerCell.cellStyle.fontColor = '#FFFFFF';
      headerCell.cellStyle.bold = true;
    }
    
    summarySheet.autoFitColumn(1);
    summarySheet.autoFitColumn(2);
  }

  void _addStatisticsSheet(xlsio.Workbook workbook, List<TransactionModel> transactions) {
    final statsSheet = workbook.worksheets.add();
    statsSheet.name = 'الإحصائيات';
    
    // Category statistics
    statsSheet.getRangeByIndex(1, 1).setText('الفئة');
    statsSheet.getRangeByIndex(1, 2).setText('المبلغ');
    
    final categoryTotals = _getCategoryTotals(transactions);
    int row = 2;
    
    for (final entry in categoryTotals.entries.take(10)) {
      statsSheet.getRangeByIndex(row, 1).setText(entry.key);
      statsSheet.getRangeByIndex(row, 2).setNumber(entry.value);
      row++;
    }
    
    // City statistics
    statsSheet.getRangeByIndex(1, 4).setText('المدينة');
    statsSheet.getRangeByIndex(1, 5).setText('المبلغ');
    
    final cityTotals = _getCityTotals(transactions);
    row = 2;
    
    for (final entry in cityTotals.entries.take(10)) {
      statsSheet.getRangeByIndex(row, 4).setText(entry.key);
      statsSheet.getRangeByIndex(row, 5).setNumber(entry.value);
      row++;
    }
    
    // Format headers
    for (int i = 1; i <= 5; i++) {
      if (i == 1 || i == 2 || i == 4 || i == 5) {
        final headerCell = statsSheet.getRangeByIndex(1, i);
        headerCell.cellStyle.backColor = '#FF9800';
        headerCell.cellStyle.fontColor = '#FFFFFF';
        headerCell.cellStyle.bold = true;
      }
    }
    
    for (int i = 1; i <= 5; i++) {
      statsSheet.autoFitColumn(i);
    }
  }

  Future<String> _saveExcelFile(xlsio.Workbook workbook) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/money_manager_export_$timestamp.xlsx';
    
    final List<int> bytes = workbook.saveAsStream();
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    
    return filePath;
  }

  // ========== Export to PDF ==========

  Future<String?> exportToPdf({
    DateTime? startDate, 
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    try {
      return await PdfExportService.instance.exportToPdfWithFilters(
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        cities: cities,
        transactionType: transactionType,
        db: _db,
      );
    } catch (e) {
      throw Exception('فشل في تصدير PDF: $e');
    }
  }

  Future<List<TransactionModel>> _getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    try {
      List<TransactionModel> transactions = await _db.getAllTransactions();
      
      // Apply filters
      if (startDate != null) {
        transactions = transactions.where((t) => 
            t.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
      }
      
      if (endDate != null) {
        transactions = transactions.where((t) => 
            t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }
      
      if (categories != null && categories.isNotEmpty) {
        transactions = transactions.where((t) => 
            categories.contains(t.category)).toList();
      }
      
      if (cities != null && cities.isNotEmpty) {
        transactions = transactions.where((t) => 
            cities.contains(t.city)).toList();
      }
      
      if (transactionType != null && transactionType != 'all') {
        transactions = transactions.where((t) => 
            t.type == transactionType).toList();
      }
      
      return transactions;
    } catch (e) {
      throw Exception('فشل في جلب البيانات: $e');
    }
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

  Map<String, double> _getCityTotals(List<TransactionModel> transactions) {
    final Map<String, double> cityTotals = {};
    
    for (final transaction in transactions) {
      if (transaction.type == 'expense' || transaction.type == 'commitment') {
        cityTotals[transaction.city] = 
            (cityTotals[transaction.city] ?? 0) + transaction.amount;
      }
    }
    
    return Map.fromEntries(
      cityTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
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

    final balance = totalIncome - (totalExpenses + totalCommitments);

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalCommitments': totalCommitments,
      'balance': balance,
    };
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

  // ========== Export to JSON ==========

  Future<String?> exportToJson({
    DateTime? startDate, 
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    try {
      final transactions = await _getFilteredTransactions(
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
        'export_date': DateTime.now().toIso8601String(),
        'total_transactions': transactions.length,
        'filters': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'categories': categories,
          'cities': cities,
          'transaction_type': transactionType,
        },
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/money_manager_backup_$timestamp.json';
      
      final File file = File(filePath);
      await file.writeAsString(jsonEncode(exportData));
      
      return filePath;
    } catch (e) {
      throw Exception('فشل في تصدير JSON: $e');
    }
  }

  // ========== Share Excel File ==========

  Future<void> shareExcelFile(String filePath) async {
    try {
      await shareFile(filePath, subject: 'تصدير Excel - مدير الأموال');
    } catch (e) {
      throw Exception('فشل في مشاركة ملف Excel: $e');
    }
  }

  // ========== Share Files ==========

  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'تصدير بيانات مدير الأموال',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة الملف: $e');
    }
  }

  // ========== Import from Excel ==========

  Future<ImportResult> importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.cancelled();
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      // Create workbook from bytes using the correct constructor
      final xlsio.Workbook workbook = xlsio.Workbook();
      
      // Alternative approach - parse CSV instead of Excel for now
      // This is a temporary solution until xlsio version is compatible
      workbook.dispose();
      
      // For now, let's suggest the user to export as CSV first
      return ImportResult.error(
        'استيراد Excel غير مدعوم حالياً. يرجى تصدير البيانات كـ CSV أو JSON واستيرادها.'
      );

    } catch (e) {
      return ImportResult.error('فشل في استيراد الملف: $e');
    }
  }

  // ========== Import from CSV ==========

  Future<ImportResult> importFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.cancelled();
      }

      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString(encoding: utf8);
      
      final List<List<dynamic>> csvRows = const CsvToListConverter().convert(csvContent);
      
      if (csvRows.isEmpty) {
        return ImportResult.error('الملف فارغ أو لا يحتوي على بيانات');
      }

      final List<TransactionModel> transactions = [];
      int importedCount = 0;
      int skippedCount = 0;

      // Skip header row, start from index 1
      for (int i = 1; i < csvRows.length; i++) {
        try {
          final row = csvRows[i];
          if (row.length < 5) {
            skippedCount++;
            continue;
          }

          final transaction = _parseCsvRow(row);
          if (transaction != null) {
            transactions.add(transaction);
            importedCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          skippedCount++;
        }
      }

      if (transactions.isEmpty) {
        return ImportResult.error('لم يتم العثور على بيانات صالحة للاستيراد');
      }

      // Save transactions to database
      for (final transaction in transactions) {
        await _db.insertTransaction(transaction);
      }

      return ImportResult.success(
        importedCount: importedCount,
        skippedCount: skippedCount,
      );

    } catch (e) {
      return ImportResult.error('فشل في استيراد ملف CSV: $e');
    }
  }

  TransactionModel? _parseCsvRow(List<dynamic> row) {
    try {
      if (row.length < 5) return null;

      // Parse date (column 1)
      String? dateStr = row[0]?.toString();
      if (dateStr == null || dateStr.isEmpty) return null;
      
      DateTime finalDate = DateTime.now();
      try {
        finalDate = DateTime.parse(dateStr);
      } catch (e) {
        try {
          finalDate = DateFormat('yyyy/MM/dd').parse(dateStr);
        } catch (e2) {
          try {
            finalDate = DateFormat('dd/MM/yyyy').parse(dateStr);
          } catch (e3) {
            return null;
          }
        }
      }

      // Parse type (column 3)
      String? typeStr = row[2]?.toString();
      if (typeStr == null || typeStr.isEmpty) return null;
      
      String type = 'expense';
      if (typeStr.contains('دخل') || typeStr.toLowerCase().contains('income')) {
        type = 'income';
      } else if (typeStr.contains('التزام') || typeStr.toLowerCase().contains('commitment')) {
        type = 'commitment';
      }

      // Parse description (column 4)
      String? description = row[3]?.toString();
      if (description == null || description.isEmpty) return null;

      // Parse amount (column 5)
      double amount = 0.0;
      try {
        amount = double.parse(row[4].toString());
      } catch (e) {
        return null;
      }

      // Parse city (column 6)
      String city = 'غير محدد';
      if (row.length > 5 && row[5] != null) {
        city = row[5].toString();
        if (city.isEmpty) city = 'غير محدد';
      }

      // Parse category (column 7)
      String category = 'أخرى';
      if (row.length > 6 && row[6] != null) {
        category = row[6].toString();
        if (category.isEmpty) category = 'أخرى';
      }

      // Parse recurring (column 8)
      bool isRecurring = false;
      if (row.length > 7 && row[7] != null) {
        String recurringStr = row[7].toString().toLowerCase();
        isRecurring = recurringStr.contains('نعم') || 
                     recurringStr.contains('true') || 
                     recurringStr.contains('yes');
      }

      // Parse notes (column 9)
      String? notes;
      if (row.length > 8 && row[8] != null) {
        notes = row[8].toString();
        if (notes.isEmpty) notes = null;
      }

      return TransactionModel(
        type: type,
        description: description,
        amount: amount,
        category: category,
        city: city,
        date: finalDate,
        isRecurring: isRecurring,
        notes: notes,
      );
    } catch (e) {
      return null;
    }
  }

  // ========== Import from JSON ==========

  Future<ImportResult> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.cancelled();
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      if (jsonData is! Map<String, dynamic> || !jsonData.containsKey('transactions')) {
        return ImportResult.error('تنسيق ملف JSON غير صحيح');
      }

      final transactionsList = jsonData['transactions'] as List;
      int importedCount = 0;
      int skippedCount = 0;

      for (final transactionData in transactionsList) {
        try {
          final transaction = TransactionModel.fromMap(transactionData);
          await _db.insertTransaction(transaction);
          importedCount++;
        } catch (e) {
          skippedCount++;
        }
      }

      return ImportResult.success(
        importedCount: importedCount,
        skippedCount: skippedCount,
      );

    } catch (e) {
      return ImportResult.error('فشل في استيراد ملف JSON: $e');
    }
  }

  // ========== Cleanup Temp Files ==========

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
            // Ignore deletion errors
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}

// ========== Import Result ==========

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
}