// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../models/transaction_model.dart';
import 'add_transaction.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'dart:math' as math;

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
      backgroundColor: _currentIndex == 0 ? AppColors.darkBackground : AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
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
      ),
      floatingActionButton: _currentIndex == 0
          ? Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.addButton,
                    AppColors.addButton.withBlue(150),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.addButton.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _showAddTransaction(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final summary = provider.monthlySummary;
          final recentTransactions = provider.getRecentTransactions(limit: 3);
          
          // حساب النسبة المئوية للالتزامات
          final double commitmentPercentage = summary != null && summary.totalIncome > 0
              ? (summary.totalCommitments / summary.totalIncome * 100)
              : 0;
          
          // حساب النسبة للدائرة (المتبقي من الدخل)
          final double remainingPercentage = summary != null && summary.totalIncome > 0
              ? (summary.balance / summary.totalIncome).clamp(0.0, 1.0)
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header with greeting
                Row(
                  children: [
                    Text(
                      'مرحباً أحمد 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Month Display
                Text(
                  DateFormat('MMMM yyyy', 'ar').format(provider.selectedMonth),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textOnDark.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Summary Cards Row
                Row(
                  children: [
                    // Income Card
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'الدخل',
                        amount: summary?.totalIncome ?? 0,
                        color: AppColors.income,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Commitments Card
                    Expanded(
                      child: _buildCommitmentCard(
                        title: 'الالتزامات',
                        amount: summary?.totalCommitments ?? 0,
                        percentage: commitmentPercentage,
                        color: AppColors.commitment,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Daily Expenses Card
                    Expanded(
                      child: _buildDailyExpenseCard(
                        title: 'المصروفات\nاليومية',
                        amount: summary?.totalExpenses ?? 0,
                        color: AppColors.dailyExpense,
                        icon: Icons.show_chart_rounded,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Remaining Balance Section
                Text(
                  'المتبقي لك هذا الشهر',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textOnDark.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Balance with Circle Progress
                Row(
                  children: [
                    // Amount
                    Text(
                      AppConstants.formatNumber(summary?.balance ?? 0),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const Spacer(),
                    // Circle Progress
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: CircleProgressPainter(
                          progress: remainingPercentage,
                          backgroundColor: AppColors.progressGray,
                          progressColor: AppColors.progressGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Recent Transactions
                Text(
                  'آخر العمليات',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textOnDark.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Transactions List
                if (recentTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'لا توجد عمليات بعد',
                        style: TextStyle(
                          color: AppColors.textOnDark.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ...recentTransactions.map((transaction) => 
                    _buildTransactionItem(transaction)
                  ).toList(),
                
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.formatNumber(amount),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentCard({
    required String title,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${AppConstants.formatNumber(amount)} ريال',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyExpenseCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: Colors.black54,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.formatNumber(amount),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final icon = _getTransactionIcon(transaction.category);
    final isExpense = transaction.type == 'expense' || transaction.type == 'commitment';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  transaction.city,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Amount
          Text(
            '${isExpense ? '' : '+'} ${AppConstants.formatMoney(transaction.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.white : AppColors.progressGreen,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String category) {
    // أيقونات حسب الفئة
    final Map<String, IconData> categoryIcons = {
      'بقالة': Icons.shopping_cart_rounded,
      'مطاعم': Icons.restaurant_rounded,
      'مواصلات': Icons.directions_car_rounded,
      'فواتير': Icons.receipt_rounded,
      'فاتورة كهرباء': Icons.bolt_rounded,
      'صحة': Icons.medical_services_rounded,
      'ترفيه': Icons.movie_rounded,
      'تسوق': Icons.shopping_bag_rounded,
      'الراتب': Icons.account_balance_wallet_rounded,
      'عمل إضافي': Icons.work_rounded,
      'استثمار': Icons.trending_up_rounded,
      'هدية': Icons.card_giftcard_rounded,
      'إيجار': Icons.home_rounded,
      'قسط سيارة': Icons.directions_car_rounded,
      'قسط قرض': Icons.account_balance_rounded,
      'اشتراكات': Icons.subscriptions_rounded,
      'تأمين': Icons.security_rounded,
    };
    
    return categoryIcons[category] ?? Icons.attach_money_rounded;
  }
}

// Custom Painter for Circle Progress
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  
  CircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background Circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius - 4, backgroundPaint);
    
    // Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final progressAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      progressAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}