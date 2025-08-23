// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/summary_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ReportsScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // تحميل البيانات الأولية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'التقارير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'السجل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddTransaction(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = provider.monthlySummary;
          final recentTransactions = provider.getRecentTransactions(limit: 3);
          final arabicFormat = DateFormat('MMMM yyyy', 'ar');

          return CustomScrollView(
            slivers: [
              // العنوان والشهر
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Column(
                  children: [
                    const Text(
                      'مدير الأموال',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      arabicFormat.format(provider.selectedMonth),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month_rounded),
                    onPressed: () => _selectMonth(context, provider),
                  ),
                ],
              ),

              // بطاقات الملخص
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'الدخل',
                              amount: summary?.totalIncome ?? 0,
                              color: AppColors.income,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'الالتزامات',
                              amount: summary?.totalCommitments ?? 0,
                              color: AppColors.commitment,
                              icon: Icons.event_repeat_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'المصروفات',
                              amount: summary?.totalExpenses ?? 0,
                              color: AppColors.expense,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // بطاقة الرصيد المتبقي
                      BalanceCard(
                        balance: summary?.balance ?? 0,
                        totalIncome: summary?.totalIncome ?? 0,
                        totalExpenses: (summary?.totalExpenses ?? 0) + 
                                      (summary?.totalCommitments ?? 0),
                      ),
                    ],
                  ),
                ),
              ),

              // آخر العمليات
              if (recentTransactions.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'آخر العمليات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // الانتقال إلى تاب السجل
                            if (context.mounted) {
                              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                              homeState?.setState(() {
                                homeState._currentIndex = 2;
                              });
                            }
                          },
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return TransactionItem(
                        transaction: recentTransactions[index],
                        onTap: () {
                          // يمكن إضافة شاشة التفاصيل هنا
                        },
                      );
                    },
                    childCount: recentTransactions.length,
                  ),
                ),
              ] else ...[
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد عمليات بعد',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اضغط على + لإضافة أول عملية',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context, TransactionProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('ar', 'SA'),
    );

    if (picked != null) {
      provider.changeMonth(picked);
    }
  }
}