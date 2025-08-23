// screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month'; // month, year, custom
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final summary = provider.monthlySummary;
          
          return Column(
            children: [
              // العنوان
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'التقارير والإحصائيات',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // اختيار الفترة
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'month',
                          label: Text('شهري'),
                          icon: Icon(Icons.calendar_view_month),
                        ),
                        ButtonSegment(
                          value: 'year',
                          label: Text('سنوي'),
                          icon: Icon(Icons.calendar_today),
                        ),
                        ButtonSegment(
                          value: 'custom',
                          label: Text('مخصص'),
                          icon: Icon(Icons.date_range),
                        ),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (value) {
                        setState(() {
                          _selectedPeriod = value.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // التابات
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'نظرة عامة'),
                  Tab(text: 'الفئات'),
                  Tab(text: 'المدن'),
                ],
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
              ),
              
              // محتوى التابات
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(provider, summary),
                    _buildCategoriesTab(provider, summary),
                    _buildCitiesTab(provider, summary),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // تاب النظرة العامة
  Widget _buildOverviewTab(TransactionProvider provider, MonthlySummary? summary) {
    if (summary == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // البطاقات الإحصائية
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'معدل الادخار',
                  value: '${summary.savingsRate.toStringAsFixed(1)}%',
                  icon: Icons.savings,
                  color: AppColors.success,
                  subtitle: 'من الدخل الشهري',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'معدل الإنفاق',
                  value: '${summary.expenseRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: AppColors.warning,
                  subtitle: 'من الدخل الشهري',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // الرسم البياني الخطي
          const Text(
            'الاتجاه الشهري',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildLineChart(provider),
          ),
          const SizedBox(height: 24),
          
          // الرسم البياني الدائري
          const Text(
            'توزيع المصروفات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildPieChart(summary),
          ),
        ],
      ),
    );
  }

  // تاب الفئات
  Widget _buildCategoriesTab(TransactionProvider provider, MonthlySummary? summary) {
    if (summary == null || summary.expensesByCategory.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final sortedCategories = summary.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // الرسم البياني الأفقي
          return Container(
            height: 400,
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildBarChart(summary),
          );
        }

        final category = sortedCategories[index - 1];
        final budget = provider.getBudgetForCategory(category.key);
        final progress = provider.getCategoryBudgetProgress(category.key);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.expense.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category,
                color: AppColors.expense,
              ),
            ),
            title: Text(
              category.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatMoney(category.value)),
                if (budget != null) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.8 ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'من ${formatMoney(budget.amount)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            trailing: Text(
              '${((category.value / summary.totalExpenses) * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
            ),
          ),
        );
      },
    );
  }

  // تاب المدن
  Widget _buildCitiesTab(TransactionProvider provider, MonthlySummary? summary) {
    if (summary == null || summary.expensesByCity.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final sortedCities = summary.expensesByCity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCities.length,
      itemBuilder: (context, index) {
        final city = sortedCities[index];
        final percentage = (city.value / summary.totalExpenses) * 100;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_city,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              city.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatMoney(city.value)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper function to format money
  String formatMoney(double amount) {
    return '${amount.toStringAsFixed(2)} ر.س';
  }

  // الرسم البياني الخطي
  Widget _buildLineChart(TransactionProvider provider) {
  return Center(
    child: Text(
      'الرسم البياني الخطي (سيتم تفعيله لاحقاً)',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}
  // الرسم البياني الدائري
  Widget _buildPieChart(MonthlySummary summary) {
    final data = summary.expensesByCategory.entries.toList();
    final colors = [
      AppColors.income,
      AppColors.expense,
      AppColors.commitment,
      AppColors.warning,
      AppColors.error,
      AppColors.primary,
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final percentage = (category.value / summary.totalExpenses) * 100;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: category.value,
            title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  // الرسم البياني الأفقي
 Widget _buildBarChart(MonthlySummary summary) {
  return Center(
    child: Text(
      'الرسم البياني الأفقي (سيتم تفعيله لاحقاً)',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}


}