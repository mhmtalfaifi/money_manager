// services/pdf_export_service.dart - الإصدار المصحح

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/transaction_model.dart';
import '../helpers/database_helper.dart';

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  static PdfExportService get instance => _instance;
  PdfExportService._internal();

  // متغيرات للخط العربي
  pw.Font? _arabicRegularFont;
  pw.Font? _arabicBoldFont;
  
  // الألوان المستخدمة في التقرير
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1B5E20);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor accentColor = PdfColor.fromInt(0xFFC5D300);
  static const PdfColor errorColor = PdfColor.fromInt(0xFFD32F2F);
  static const PdfColor lightGreen = PdfColor.fromInt(0xFF81C784);
  static const PdfColor lightBlue = PdfColor.fromInt(0xFF64B5F6);
  static const PdfColor lightOrange = PdfColor.fromInt(0xFFFFB74D);

  // دالة لتحميل الخطوط العربية
  Future<void> _loadArabicFonts() async {
    if (_arabicRegularFont != null && _arabicBoldFont != null) return;
    
    try {
      final regularFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      _arabicRegularFont = pw.Font.ttf(regularFontData);
      
      final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      _arabicBoldFont = pw.Font.ttf(boldFontData);
    } catch (e) {
      print('فشل تحميل الخطوط العربية: $e');
      // استخدام الخطوط الافتراضية
      _arabicRegularFont = pw.Font.helvetica();
      _arabicBoldFont = pw.Font.helveticaBold();
    }
  }

  // دالة معالجة النص العربي
  String _processArabicText(String text) {
    if (text.isEmpty) return text;
    
    text = text.trim();
    
    // تحويل الأرقام العربية إلى إنجليزية
    final arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    
    for (int i = 0; i < arabicNumbers.length; i++) {
      text = text.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    
    return text;
  }

  // دالة إنشاء أنماط النص بالخط العربي
  pw.TextStyle _getArabicTextStyle({
    double fontSize = 12, 
    bool bold = false, 
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold ? _arabicBoldFont : _arabicRegularFont,
      fontSize: fontSize,
      color: color ?? PdfColors.black,
    );
  }

  // دالة إنشاء نص عربي مع معالجة الاتجاه
  pw.Widget _buildArabicText(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        _processArabicText(text),
        style: style,
        textAlign: textAlign,
      ),
    );
  }

  // دالة إنشاء لون شفاف (بديل withOpacity)
  PdfColor _createTransparentColor(PdfColor baseColor, double opacity) {
    // تحويل إلى RGB ثم إنشاء لون جديد بشفافية
    final int red = ((baseColor.red * 255).round() * opacity).round();
    final int green = ((baseColor.green * 255).round() * opacity).round();
    final int blue = ((baseColor.blue * 255).round() * opacity).round();
    
    return PdfColor.fromInt(0xFF000000 | (red << 16) | (green << 8) | blue);
  }

  Future<String> exportToPdf(List<TransactionModel> transactions) async {
    await _loadArabicFonts();
    
    final pdf = pw.Document();

    // صفحة الغلاف
    await _addCoverPage(pdf, transactions);

    // صفحة الملخص التنفيذي
    await _addExecutiveSummary(pdf, transactions);

    // صفحة الإحصائيات المالية
    await _addFinancialStatistics(pdf, transactions);

    // صفحة تحليل الفئات
    await _addCategoryAnalysis(pdf, transactions);

    // صفحة تحليل المدن
    await _addCityAnalysis(pdf, transactions);

    // صفحة العمليات التفصيلية
    await _addDetailedTransactions(pdf, transactions);

    // حفظ الملف
    return await _saveFile(pdf);
  }

  // صفحة الغلاف المحسنة
  Future<void> _addCoverPage(pw.Document pdf, List<TransactionModel> transactions) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // شعار التطبيق
                  pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '💰',
                        style: pw.TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                  
                  pw.SizedBox(height: 40),
                  
                  // عنوان التقرير
                  _buildArabicText(
                    'التقرير المالي الشامل',
                    style: _getArabicTextStyle(
                      fontSize: 36, 
                      bold: true, 
                      color: PdfColors.white
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  _buildArabicText(
                    'مدير الأموال الشخصية',
                    style: _getArabicTextStyle(
                      fontSize: 20, 
                      color: PdfColors.white
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  
                  pw.SizedBox(height: 60),
                  
                  // معلومات التقرير
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: lightGreen,
                      borderRadius: pw.BorderRadius.circular(15),
                    ),
                    child: pw.Column(
                      children: [
                        _buildArabicText(
                          'تاريخ التصدير: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
                          style: _getArabicTextStyle(
                            fontSize: 14, 
                            color: PdfColors.white
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 8),
                        _buildArabicText(
                          'إجمالي العمليات: ${transactions.length} عملية',
                          style: _getArabicTextStyle(
                            fontSize: 14, 
                            color: PdfColors.white
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // صفحة الملخص التنفيذي
  Future<void> _addExecutiveSummary(pw.Document pdf, List<TransactionModel> transactions) async {
    final summary = _calculateSummary(transactions);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // العنوان
                _buildSectionHeader('الملخص التنفيذي'),
                
                pw.SizedBox(height: 30),
                
                // البطاقات المالية الرئيسية
                pw.Row(
                  children: [
                    _buildSummaryCard(
                      'إجمالي الدخل',
                      summary['totalIncome'],
                      primaryColor,
                      '↓',
                    ),
                    pw.SizedBox(width: 20),
                    _buildSummaryCard(
                      'إجمالي المصروفات',
                      summary['totalExpenses'],
                      errorColor,
                      '↑',
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                pw.Row(
                  children: [
                    _buildSummaryCard(
                      'الالتزامات',
                      summary['totalCommitments'],
                      lightOrange,
                      '⟳',
                    ),
                    pw.SizedBox(width: 20),
                    _buildSummaryCard(
                      'الرصيد المتبقي',
                      summary['balance'],
                      summary['balance'] >= 0 ? primaryColor : errorColor,
                      '₪',
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                
                // مؤشرات الأداء المالي
                _buildPerformanceIndicators(summary),
                
                pw.SizedBox(height: 30),
                
                // نصائح مالية
                _buildFinancialTips(summary),
              ],
            ),
          );
        },
      ),
    );
  }

  // صفحة الإحصائيات المالية
  Future<void> _addFinancialStatistics(pw.Document pdf, List<TransactionModel> transactions) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('الإحصائيات المالية'),
                
                pw.SizedBox(height: 30),
                
                // إحصائيات العمليات
                _buildTransactionStatistics(transactions),
                
                pw.SizedBox(height: 30),
                
                // التوزيع الشهري
                _buildMonthlyDistribution(transactions),
                
                pw.SizedBox(height: 30),
                
                // رسم بياني للفئات
                _buildCategoryChart(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  // صفحة تحليل الفئات
  Future<void> _addCategoryAnalysis(pw.Document pdf, List<TransactionModel> transactions) async {
    final categoryTotals = _getCategoryTotals(transactions);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('تحليل الفئات'),
                
                pw.SizedBox(height: 30),
                
                // جدول أهم الفئات
                _buildCategoryTable(categoryTotals),
                
                pw.SizedBox(height: 30),
                
                // نصائح حول الفئات
                _buildCategoryRecommendations(categoryTotals),
              ],
            ),
          );
        },
      ),
    );
  }

  // صفحة تحليل المدن
  Future<void> _addCityAnalysis(pw.Document pdf, List<TransactionModel> transactions) async {
    final cityTotals = _getCityTotals(transactions);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('تحليل المدن'),
                pw.SizedBox(height: 30),
                _buildCityTable(cityTotals),
              ],
            ),
          );
        },
      ),
    );
  }

  // صفحة العمليات التفصيلية
  Future<void> _addDetailedTransactions(pw.Document pdf, List<TransactionModel> transactions) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('العمليات التفصيلية'),
                pw.SizedBox(height: 20),
                _buildTransactionsTable(transactions.take(15).toList()),
              ],
            ),
          );
        },
      ),
    );
  }

  // دوال مساعدة لبناء المكونات

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: lightBlue,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border(
          right: pw.BorderSide(
            color: primaryColor,
            width: 4,
          ),
        ),
      ),
      child: _buildArabicText(
        title,
        style: _getArabicTextStyle(
          fontSize: 24,
          bold: true,
          color: primaryColor,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryCard(String title, double value, PdfColor color, String icon) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(15),
          border: pw.Border.all(color: color, width: 2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              icon,
              style: pw.TextStyle(fontSize: 24, color: color),
            ),
            pw.SizedBox(height: 10),
            _buildArabicText(
              title,
              style: _getArabicTextStyle(fontSize: 14, color: color, bold: true),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '${value.toStringAsFixed(2)} ر.س',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPerformanceIndicators(Map<String, dynamic> summary) {
    final savingsRate = summary['savingsRate'] as double;
    final expenseRate = summary['expenseRate'] as double;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildArabicText(
            'مؤشرات الأداء المالي',
            style: _getArabicTextStyle(fontSize: 18, bold: true),
          ),
          pw.SizedBox(height: 15),
          _buildIndicatorRow('معدل الادخار', '${savingsRate.toStringAsFixed(1)}%', 
                           savingsRate >= 20 ? primaryColor : errorColor),
          pw.SizedBox(height: 8),
          _buildIndicatorRow('معدل الإنفاق', '${expenseRate.toStringAsFixed(1)}%', 
                           expenseRate <= 80 ? primaryColor : errorColor),
          pw.SizedBox(height: 8),
          _buildIndicatorRow('عدد العمليات', '${summary['totalTransactions']}', primaryColor),
        ],
      ),
    );
  }

  pw.Widget _buildIndicatorRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildArabicText(
          label,
          style: _getArabicTextStyle(fontSize: 14),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFinancialTips(Map<String, dynamic> summary) {
    final List<String> tips = _generateFinancialTips(summary);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildArabicText(
            'نصائح مالية',
            style: _getArabicTextStyle(fontSize: 18, bold: true, color: primaryColor),
          ),
          pw.SizedBox(height: 15),
          ...tips.take(3).map((tip) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  margin: const pw.EdgeInsets.only(top: 6, left: 8),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: _buildArabicText(
                    tip,
                    style: _getArabicTextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionStatistics(List<TransactionModel> transactions) {
    final incomeTransactions = transactions.where((t) => t.type == 'income').length;
    final expenseTransactions = transactions.where((t) => t.type == 'expense').length;
    final commitmentTransactions = transactions.where((t) => t.type == 'commitment').length;
    
    return pw.Container(
      child: pw.Column(
        children: [
          _buildStatRow('عمليات الدخل', incomeTransactions, primaryColor),
          pw.SizedBox(height: 10),
          _buildStatRow('عمليات المصروفات', expenseTransactions, errorColor),
          pw.SizedBox(height: 10),
          _buildStatRow('عمليات الالتزامات', commitmentTransactions, lightOrange),
        ],
      ),
    );
  }

  pw.Widget _buildStatRow(String label, int count, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildArabicText(label, style: _getArabicTextStyle(fontSize: 14)),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text('$count', style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  pw.Widget _buildMonthlyDistribution(List<TransactionModel> transactions) {
    return _buildArabicText('التوزيع الزمني للعمليات متاح في التحليل التفصيلي', 
      style: _getArabicTextStyle(fontSize: 12, color: PdfColors.grey));
  }

  pw.Widget _buildCategoryChart(List<TransactionModel> transactions) {
    return _buildArabicText('الرسوم البيانية متاحة في النسخة المتقدمة', 
      style: _getArabicTextStyle(fontSize: 12, color: PdfColors.grey));
  }

  pw.Widget _buildCategoryTable(Map<String, double> categoryTotals) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: _buildArabicText('الفئة', style: _getArabicTextStyle(bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: _buildArabicText('المبلغ (ر.س)', style: _getArabicTextStyle(bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: _buildArabicText('النسبة %', style: _getArabicTextStyle(bold: true)),
            ),
          ],
        ),
        ...categoryTotals.entries.take(10).map((entry) {
          final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: _buildArabicText(entry.key, style: _getArabicTextStyle(fontSize: 11)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${entry.value.toStringAsFixed(2)}', 
                  style: pw.TextStyle(fontSize: 11)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${percentage.toStringAsFixed(1)}%', 
                  style: pw.TextStyle(fontSize: 11)),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildCategoryRecommendations(Map<String, double> categoryTotals) {
    return _buildArabicText('راجع الفئات الأعلى إنفاقاً وابحث عن فرص للتوفير',
      style: _getArabicTextStyle(fontSize: 12, color: PdfColors.grey));
  }

  pw.Widget _buildCityTable(Map<String, double> cityTotals) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: _buildArabicText('المدينة', style: _getArabicTextStyle(bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: _buildArabicText('المبلغ (ر.س)', style: _getArabicTextStyle(bold: true)),
            ),
          ],
        ),
        ...cityTotals.entries.take(10).map((entry) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: _buildArabicText(entry.key, style: _getArabicTextStyle(fontSize: 11)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${entry.value.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11)),
            ),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTransactionsTable(List<TransactionModel> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: _buildArabicText('الوصف', style: _getArabicTextStyle(fontSize: 10, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: _buildArabicText('النوع', style: _getArabicTextStyle(fontSize: 10, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: _buildArabicText('المبلغ', style: _getArabicTextStyle(fontSize: 10, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: _buildArabicText('الفئة', style: _getArabicTextStyle(fontSize: 10, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: _buildArabicText('التاريخ', style: _getArabicTextStyle(fontSize: 10, bold: true)),
            ),
          ],
        ),
        ...transactions.map((transaction) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: _buildArabicText(transaction.description, style: _getArabicTextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: _buildArabicText(_getTypeLabel(transaction.type), style: _getArabicTextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${transaction.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: _buildArabicText(transaction.category, style: _getArabicTextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(DateFormat('MM/dd').format(transaction.date), style: pw.TextStyle(fontSize: 9)),
            ),
          ],
        )),
      ],
    );
  }

  // دوال الحسابات والتحليل
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
    final savingsRate = totalIncome > 0 ? ((balance / totalIncome) * 100) : 0.0;
    final expenseRate = totalIncome > 0 ? (((totalExpenses + totalCommitments) / totalIncome) * 100) : 0.0;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalCommitments': totalCommitments,
      'balance': balance,
      'savingsRate': savingsRate,
      'expenseRate': expenseRate,
      'totalTransactions': transactions.length,
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

  List<String> _generateFinancialTips(Map<String, dynamic> summary) {
    final List<String> tips = [];
    final savingsRate = summary['savingsRate'] as double;
    final balance = summary['balance'] as double;
    
    if (savingsRate < 10) {
      tips.add('حاول توفير 10% على الأقل من دخلك الشهري لبناء وضع مالي مستقر');
    }
    
    if (balance < 0) {
      tips.add('لديك عجز في الميزانية، راجع مصروفاتك وحاول تقليل النفقات غير الضرورية');
    } else {
      tips.add('رصيدك إيجابي، فكر في استثمار الفائض لتحقيق عوائد إضافية');
    }
    
    tips.add('راجع فئات الإنفاق الأعلى وحدد إمكانيات للتوفير');
    tips.add('ضع ميزانية شهرية والتزم بها لتحقيق أهدافك المالية');
    tips.add('احتفظ بصندوق طوارئ يكفي 3-6 أشهر من المصروفات الأساسية');
    
    return tips;
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

  Future<String> _saveFile(pw.Document pdf) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/financial_report_$timestamp.pdf';
    
    final File file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }

  // دالة تصدير مع فلاتر محسنة
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
}