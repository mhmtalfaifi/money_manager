// services/pdf_export_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';
import '../helpers/database_helper.dart';

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  static PdfExportService get instance => _instance;
  PdfExportService._internal();

  // متغيرات للخط العربي
  pw.Font? _arabicRegularFont;
  pw.Font? _arabicBoldFont;

  // دالة لتحميل الخطوط العربية
  Future<void> _loadArabicFonts() async {
    if (_arabicRegularFont != null && _arabicBoldFont != null) return;
    
    try {
      // تحميل الخط العادي
      final regularFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      _arabicRegularFont = pw.Font.ttf(regularFontData);
      
      // تحميل الخط الغامق
      final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      _arabicBoldFont = pw.Font.ttf(boldFontData);
    } catch (e) {
      print('فشل تحميل الخطوط العربية: $e');
      // يمكنك إضافة خط افتراضي هنا إذا لزم الأمر
    }
  }

  // دالة مساعدة لإنشاء أنماط النص بالخط العربي
  pw.TextStyle _getArabicTextStyle({double fontSize = 12, bool bold = false, PdfColor? color}) {
    return pw.TextStyle(
      font: bold ? _arabicBoldFont : _arabicRegularFont,
      fontSize: fontSize,
      color: color,
    );
  }

  Future<String> exportToPdf(List<TransactionModel> transactions) async {
    // تحميل الخطوط العربية أولاً
    await _loadArabicFonts();
    
    final pdf = pw.Document();

    // إضافة صفحة الغلاف
    _addCoverPage(pdf);

    // إضافة صفحة الملخص
    _addSummaryPage(pdf, transactions);

    // إضافة صفحة العمليات
    _addTransactionsPage(pdf, transactions);

    // إضافة صفحة الإحصائيات
    _addStatisticsPage(pdf, transactions);

    // حفظ الملف
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/money_manager_export_$timestamp.pdf';
    
    final File file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }

  void _addCoverPage(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'التقرير المالي',
                  style: _getArabicTextStyle(fontSize: 32, bold: true, color: PdfColors.green),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'مدير الأموال',
                  style: _getArabicTextStyle(fontSize: 24, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'تاريخ التصدير: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
                  style: _getArabicTextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addSummaryPage(pw.Document pdf, List<TransactionModel> transactions) {
    final summary = _calculateSummary(transactions);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ملخص مالي',
                  style: _getArabicTextStyle(fontSize: 24, bold: true),
                ),
                pw.SizedBox(height: 30),
                _buildSummaryItem('إجمالي الدخل', summary['totalIncome']),
                _buildSummaryItem('إجمالي المصروفات', summary['totalExpenses']),
                _buildSummaryItem('إجمالي الالتزامات', summary['totalCommitments']),
                _buildSummaryItem('الرصيد المتبقي', summary['balance']),
                _buildSummaryItem('عدد العمليات', transactions.length.toString()),
                _buildSummaryItem('معدل الادخار %', summary['savingsRate']),
                pw.SizedBox(height: 30),
                pw.Text(
                  'ملخص الفئات',
                  style: _getArabicTextStyle(fontSize: 18, bold: true),
                ),
                pw.SizedBox(height: 15),
                ..._buildCategorySummary(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addTransactionsPage(pw.Document pdf, List<TransactionModel> transactions) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'تفاصيل العمليات',
                  style: _getArabicTextStyle(fontSize: 24, bold: true),
                ),
                pw.SizedBox(height: 20),
                _buildTransactionsTable(transactions.take(20).toList()),
                if (transactions.length > 20)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: pw.Text(
                      'عرض ${20} من أصل ${transactions.length} عملية',
                      style: _getArabicTextStyle(fontSize: 10, color: PdfColors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addStatisticsPage(pw.Document pdf, List<TransactionModel> transactions) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'الإحصائيات',
                  style: _getArabicTextStyle(fontSize: 24, bold: true),
                ),
                pw.SizedBox(height: 30),
                _buildTopCategoriesSection(transactions),
                pw.SizedBox(height: 30),
                _buildTopCitiesSection(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: _getArabicTextStyle(fontSize: 14, bold: true),
          ),
          pw.Text(
            value.toString(),
            style: _getArabicTextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildCategorySummary(List<TransactionModel> transactions) {
    final categoryTotals = _getCategoryTotals(transactions);
    return categoryTotals.entries.take(5).map((entry) => 
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(entry.key, style: _getArabicTextStyle(fontSize: 12)),
            pw.Text('${entry.value.toStringAsFixed(2)} ر.س', 
                   style: _getArabicTextStyle(fontSize: 12)),
          ],
        ),
      ),
    ).toList();
  }

  pw.Widget _buildTransactionsTable(List<TransactionModel> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('الوصف', style: _getArabicTextStyle(fontSize: 12, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('النوع', style: _getArabicTextStyle(fontSize: 12, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('المبلغ', style: _getArabicTextStyle(fontSize: 12, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('التاريخ', style: _getArabicTextStyle(fontSize: 12, bold: true)),
            ),
          ],
        ),
        // Data rows
        ...transactions.map((transaction) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(transaction.description, style: _getArabicTextStyle(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(_getTypeLabel(transaction.type), style: _getArabicTextStyle(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${transaction.amount.toStringAsFixed(2)} ر.س', 
                           style: _getArabicTextStyle(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(DateFormat('yyyy/MM/dd').format(transaction.date), 
                           style: _getArabicTextStyle(fontSize: 10)),
            ),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTopCategoriesSection(List<TransactionModel> transactions) {
    final topCategories = _getTopCategories(transactions);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'أكثر الفئات إنفاقاً',
          style: _getArabicTextStyle(fontSize: 18, bold: true),
        ),
        pw.SizedBox(height: 15),
        ...topCategories.map((category) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(category['category'], style: _getArabicTextStyle(fontSize: 12)),
              pw.Text('${category['amount'].toStringAsFixed(2)} ر.س', 
                     style: _getArabicTextStyle(fontSize: 12)),
            ],
          ),
        )),
      ],
    );
  }

  pw.Widget _buildTopCitiesSection(List<TransactionModel> transactions) {
    final topCities = _getTopCities(transactions);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'أكثر المدن إنفاقاً',
          style: _getArabicTextStyle(fontSize: 18, bold: true),
        ),
        pw.SizedBox(height: 15),
        ...topCities.map((city) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(city['city'], style: _getArabicTextStyle(fontSize: 12)),
              pw.Text('${city['amount'].toStringAsFixed(2)} ر.س', 
                     style: _getArabicTextStyle(fontSize: 12)),
            ],
          ),
        )),
      ],
    );
  }

  // باقي الدوال تبقى كما هي بدون تغيير...
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
    final savingsRate = totalIncome > 0 ? 
        ((totalIncome - totalExpenses - totalCommitments) / totalIncome * 100).toStringAsFixed(1) : '0.0';

    return {
      'totalIncome': '${totalIncome.toStringAsFixed(2)} ر.س',
      'totalExpenses': '${totalExpenses.toStringAsFixed(2)} ر.س',
      'totalCommitments': '${totalCommitments.toStringAsFixed(2)} ر.س',
      'balance': '${balance.toStringAsFixed(2)} ر.س',
      'savingsRate': savingsRate,
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

  Future<List<TransactionModel>> _getFilteredTransactions({
    required DatabaseHelper db,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
  }) async {
    try {
      List<TransactionModel> transactions = await db.getAllTransactions();
      
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

  Future<String> exportToPdfWithFilters({
    DateTime? startDate, 
    DateTime? endDate,
    List<String>? categories,
    List<String>? cities,
    String? transactionType,
    required DatabaseHelper db,
  }) async {
    try {
      await _loadArabicFonts();
      
      List<TransactionModel> transactions = await _getFilteredTransactions(
        db: db,
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        cities: cities,
        transactionType: transactionType,
      );

      if (transactions.isEmpty) {
        throw Exception('لا توجد بيانات للتصدير');
      }

      return await exportToPdf(transactions);
    } catch (e) {
      throw Exception('فشل في تصدير PDF: $e');
    }
  }
}