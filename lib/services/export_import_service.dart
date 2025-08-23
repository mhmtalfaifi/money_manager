import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // إضافة هذا الاستيراد
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border; // إضافة هذا الاستيراد
import 'package:file_picker/file_picker.dart'; // إضافة هذا الاستيراد
import 'package:share_plus/share_plus.dart'; // إضافة هذا الاستيراد
import '../utils/app_constants.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  static ExportImportService get instance => _instance;
  ExportImportService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  // ========== تصدير إلى Excel ==========

  Future<String?> exportToExcel({DateTime? startDate, DateTime? endDate}) async {
    try {
      // الحصول على البيانات
      List<TransactionModel> transactions;
      if (startDate != null && endDate != null) {
        transactions = await _db.getTransactionsByDateRange(startDate, endDate);
      } else {
        transactions = await _db.getAllTransactions();
      }

      if (transactions.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      // إنشاء ملف Excel
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'العمليات المالية';

      // إضافة الرؤوس
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
      }

      // إضافة البيانات
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final int row = i + 2; // الصف الأول للرؤوس

        sheet.getRangeByIndex(row, 1).setText(DateFormat('yyyy-MM-dd').format(transaction.date));
        sheet.getRangeByIndex(row, 2).setText(DateFormat('HH:mm').format(transaction.date));
        sheet.getRangeByIndex(row, 3).setText(transaction.type.label);
        sheet.getRangeByIndex(row, 4).setText(transaction.description);
        sheet.getRangeByIndex(row, 5).setNumber(transaction.amount);
        sheet.getRangeByIndex(row, 6).setText(transaction.city);
        sheet.getRangeByIndex(row, 7).setText(transaction.category?.label ?? '');
        sheet.getRangeByIndex(row, 8).setText(transaction.isRecurring ? 'نعم' : 'لا');
        sheet.getRangeByIndex(row, 9).setText(transaction.notes ?? '');

        // تلوين الصفوف حسب النوع
        final String color = _getTypeColor(transaction.type);
        for (int col = 1; col <= headers.length; col++) {
          sheet.getRangeByIndex(row, col).cellStyle.backColor = color;
        }
      }

      // إضافة ورقة الملخص
      _addSummarySheet(workbook, transactions);

      // حفظ الملف
      final Directory directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '${directory.path}/money_manager_export_$timestamp.xlsx';
      
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('فشل في تصدير البيانات: $e');
    }
  }

  // إضافة ورقة الملخص
  void _addSummarySheet(Workbook workbook, List<TransactionModel> transactions) {
    final Worksheet summarySheet = workbook.worksheets.addWithName('الملخص');

    // حساب الإجماليات
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalObligations = 0;

    for (final TransactionModel transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          totalIncome += transaction.amount;
          break;
        case TransactionType.expense:
          totalExpenses += transaction.amount;
          break;
        case TransactionType.obligation:
          totalObligations += transaction.amount;
          break;
      }
    }

    final double balance = totalIncome - totalExpenses - totalObligations;

    // كتابة الملخص
    summarySheet.getRangeByIndex(1, 1).setText('الملخص المالي');
    summarySheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    summarySheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;

    final List<List<dynamic>> summaryData = [
      ['إجمالي الدخل', totalIncome],
      ['إجمالي المصروفات', totalExpenses],
      ['إجمالي الالتزامات', totalObligations],
      ['الرصيد المتبقي', balance],
      ['عدد العمليات', transactions.length],
    ];

    for (int i = 0; i < summaryData.length; i++) {
      summarySheet.getRangeByIndex(i + 3, 1)
        ..setText(summaryData[i][0].toString())
        ..cellStyle.bold = true;
      
      summarySheet.getRangeByIndex(i + 3, 2)
        .setText(summaryData[i][1].toString());
    }
  }

  String _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return '#E8F5E8';
      case TransactionType.expense:
        return '#E3F2FD';
      case TransactionType.obligation:
        return '#FFF3E0';
    }
  }

  // ========== مشاركة ملف Excel ==========

  Future<void> shareExcelFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  // ========== تصدير إلى JSON ==========

  Future<String?> exportToJson() async {
    try {
      final dynamic data = await _db.exportData();
      
      final Directory directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '${directory.path}/money_manager_backup_$timestamp.json';
      
      final File file = File(filePath);
      await file.writeAsString(jsonEncode(data));

      return filePath;
    } catch (e) {
      throw Exception('فشل في إنشاء النسخة الاحتياطية: $e');
    }
  }

  // ========== استيراد من JSON ==========

  Future<void> importFromJson() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('لم يتم اختيار ملف');
      }

      final File file = File(result.files.first.path!);
      final String content = await file.readAsString();
      final dynamic data = jsonDecode(content);

      await _db.importData(data);
    } catch (e) {
      throw Exception('فشل في استيراد البيانات: $e');
    }
  }

  // ========== استيراد من Excel ==========

  Future<int> importFromExcel() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('لم يتم اختيار ملف');
      }

      final File file = File(result.files.first.path!);
      final List<int> bytes = await file.readAsBytes();
      final Workbook workbook = Workbook(bytes);
      final Worksheet sheet = workbook.worksheets[0];

      if (sheet.rows.isEmpty) {
        throw Exception('الورقة فارغة');
      }

      int importedCount = 0;
      final List<Row> rows = sheet.rows;

      // تخطي صف الرؤوس
      for (int i = 1; i < rows.length; i++) {
        final Row row = rows[i];
        if (row.cells.length < 5) continue; // تأكد من وجود الحد الأدنى من الأعمدة

        try {
          final TransactionModel? transaction = _parseExcelRow(row.cells);
          if (transaction != null) {
            await _db.insertTransaction(transaction);
            importedCount++;
          }
        } catch (e) {
          // تجاهل الصفوف التالفة
          continue;
        }
      }

      workbook.dispose();
      return importedCount;
    } catch (e) {
      throw Exception('فشل في استيراد البيانات: $e');
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
        final DateTime time = DateFormat('HH:mm').parse(timeStr);
        finalDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }

      // تحويل النوع
      TransactionType? type;
      for (final TransactionType t in TransactionType.values) {
        if (t.label == typeStr) {
          type = t;
          break;
        }
      }
      if (type == null) return null;

      // تحويل المبلغ
      final double? amount = double.tryParse(amountStr);
      if (amount == null || amount <= 0) return null;

      // تحويل الفئة (إذا وجدت)
      ExpenseCategory? category;
      if (cells.length > 6 && cells[6].value != null) {
        final String categoryStr = cells[6].value.toString();
        for (final ExpenseCategory c in ExpenseCategory.values) {
          if (c.label == categoryStr) {
            category = c;
            break;
          }
        }
      }

      // تحويل المتكررة
      bool isRecurring = false;
      if (cells.length > 7 && cells[7].value != null) {
        isRecurring = cells[7].value.toString().toLowerCase() == 'نعم';
      }

      // الملاحظات
      String? notes;
      if (cells.length > 8 && cells[8].value != null) {
        notes = cells[8].value.toString();
        if (notes.isEmpty) notes = null;
      }

      return TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        description: description,
        amount: amount,
        date: finalDate,
        city: city ?? 'غير محدد',
        category: category,
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
          // حذف الملفات الأقدم من 7 أيام
          final FileStat stats = await file.stat();
          final Duration age = DateTime.now().difference(stats.modified);
          if (age.inDays > 7) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // تجاهل أخطاء التنظيف
    }
  }
}