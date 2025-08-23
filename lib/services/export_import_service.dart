import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '/helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For DateFormat

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
      var excel = Excel.createExcel();
      Sheet sheet = excel['العمليات المالية'];

      // إضافة الرؤوس
      final headers = [
        'التاريخ', 'الوقت', 'النوع', 'الوصف', 'المبلغ', 
        'المدينة', 'الفئة', 'متكررة', 'ملاحظات'
      ];
      
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = headers[i]
          ..cellStyle = CellStyle(
            bold: true,
            backgroundColor: '#4CAF50',
            fontColor: '#FFFFFF',
          );
      }

      // إضافة البيانات
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final row = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = DateFormat('yyyy-MM-dd').format(transaction.date);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = DateFormat('HH:mm').format(transaction.date);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = transaction.type.label;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = transaction.description;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = transaction.amount;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = transaction.city;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = transaction.category?.label ?? '';
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = transaction.isRecurring ? 'نعم' : 'لا';
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value = transaction.notes ?? '';

        // تلوين الصفوف حسب النوع
        final color = _getTypeColor(transaction.type);
        for (int col = 0; col < headers.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .cellStyle = CellStyle(backgroundColor: color);
        }
      }

      // إضافة ورقة الملخص
      _addSummarySheet(excel, transactions);

      // حفظ الملف
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/money_manager_export_$timestamp.xlsx';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('فشل في تصدير البيانات: $e');
    }
  }

  // إضافة ورقة الملخص
  void _addSummarySheet(Excel excel, List<TransactionModel> transactions) {
    Sheet summarySheet = excel['الملخص'];

    // حساب الإجماليات
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalObligations = 0;

    for (final transaction in transactions) {
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

    final balance = totalIncome - totalExpenses - totalObligations;

    // كتابة الملخص
    final summaryData = [
      ['إجمالي الدخل', totalIncome],
      ['إجمالي المصروفات', totalExpenses],
      ['إجمالي الالتزامات', totalObligations],
      ['الرصيد المتبقي', balance],
      ['عدد العمليات', transactions.length],
    ];

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = 'الملخص المالي'
      ..cellStyle = CellStyle(bold: true, fontSize: 16);

    for (int i = 0; i < summaryData.length; i++) {
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 2))
        ..value = summaryData[i][0]
        ..cellStyle = CellStyle(bold: true);
      
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 2))
        .value = summaryData[i][1];
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
      final data = await _db.exportData();
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/money_manager_backup_$timestamp.json';
      
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));

      return filePath;
    } catch (e) {
      throw Exception('فشل في إنشاء النسخة الاحتياطية: $e');
    }
  }

  // ========== استيراد من JSON ==========

  Future<void> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('لم يتم اختيار ملف');
      }

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content);

      await _db.importData(data);
    } catch (e) {
      throw Exception('فشل في استيراد البيانات: $e');
    }
  }

  // ========== استيراد من Excel ==========

  Future<int> importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('لم يتم اختيار ملف');
      }

      final file = File(result.files.first.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('الملف فارغ أو تالف');
      }

      final sheet = excel.tables.values.first;
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('الورقة فارغة');
      }

      int importedCount = 0;
      final rows = sheet.rows;

      // تخطي صف الرؤوس
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue; // تأكد من وجود الحد الأدنى من الأعمدة

        try {
          final transaction = _parseExcelRow(row);
          if (transaction != null) {
            await _db.insertTransaction(transaction);
            importedCount++;
          }
        } catch (e) {
          // تجاهل الصفوف التالفة
          continue;
        }
      }

      return importedCount;
    } catch (e) {
      throw Exception('فشل في استيراد البيانات: $e');
    }
  }

  TransactionModel? _parseExcelRow(List<Data?> row) {
    try {
      final dateStr = row[0]?.value?.toString();
      final timeStr = row[1]?.value?.toString();
      final typeStr = row[2]?.value?.toString();
      final description = row[3]?.value?.toString();
      final amountStr = row[4]?.value?.toString();
      final city = row[5]?.value?.toString() ?? 'غير محدد';

      if (dateStr == null || typeStr == null || description == null || amountStr == null) {
        return null;
      }

      // تحويل التاريخ والوقت
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      DateTime finalDate = date;
      
      if (timeStr != null && timeStr.isNotEmpty) {
        final time = DateFormat('HH:mm').parse(timeStr);
        finalDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }

      // تحويل النوع
      TransactionType? type;
      for (final t in TransactionType.values) {
        if (t.label == typeStr) {
          type = t;
          break;
        }
      }
      if (type == null) return null;

      // تحويل المبلغ
      final amount = double.tryParse(amountStr);
      if (amount == null || amount <= 0) return null;

      // تحويل الفئة (إذا وجدت)
      ExpenseCategory? category;
      if (row.length > 6 && row[6]?.value != null) {
        final categoryStr = row[6]!.value.toString();
        for (final c in ExpenseCategory.values) {
          if (c.label == categoryStr) {
            category = c;
            break;
          }
        }
      }

      // تحويل المتكررة
      bool isRecurring = false;
      if (row.length > 7 && row[7]?.value != null) {
        isRecurring = row[7]!.value.toString().toLowerCase() == 'نعم';
      }

      // الملاحظات
      String? notes;
      if (row.length > 8 && row[8]?.value != null) {
        notes = row[8]!.value.toString();
        if (notes.isEmpty) notes = null;
      }

      return TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        description: description,
        amount: amount,
        date: finalDate,
        city: city,
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
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file is File && 
            (file.path.contains('money_manager_export_') || 
             file.path.contains('money_manager_backup_'))) {
          // حذف الملفات الأقدم من 7 أيام
          final stats = await file.stat();
          final age = DateTime.now().difference(stats.modified);
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