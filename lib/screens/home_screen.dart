import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_colors.dart';
import '../models/transaction_model.dart';
import 'add_transaction.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'dart:math' as math;
import '../utils/app_constants.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
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
      context.read<UserProvider>().loadUserData();
    });
    
    // إعداد التحكم في الرسوم المتحركة
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // تأثير الاهتزاز عند النقر
    HapticFeedback.lightImpact();
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentIndex == 0 ? AppColors.background : AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBrown.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            iconSize: 26,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 0 ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: const Icon(Icons.home_rounded),
                ),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 1 ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: const Icon(Icons.pie_chart_rounded),
                ),
                label: 'التقارير',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 2 ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: const Icon(Icons.history_rounded),
                ),
                label: 'السجل',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 3 ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: const Icon(Icons.settings_rounded),
                ),
                label: 'الإعدادات',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showAddTransaction(context);
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.addButton,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightGreen.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, 
                    color: Colors.white, 
                    size: 36,
                  ),
                ),
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
    ).then((_) {
      _animationController.reverse();
    });
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // دالة لفتح منصة إحسان
  Future<void> _openEhsanPlatform(BuildContext context) async {
    String url;
    
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Theme.of(context).platform == TargetPlatform.android) {
        // للاندرويد
        url = 'https://play.google.com/store/apps/details?id=sa.gov.sdaia.ehsan';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        // للايفون
        url = 'https://apps.apple.com/us/app/ehsan-%D8%A5%D8%AD%D8%B3%D8%A7%D9%86/id1602515092';
      } else {
        // للمنصات الأخرى نستخدم الموقع الافتراضي
        url = 'https://ehsan.sa/';
      }
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح منصة إحسان')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء فتح المنصة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<TransactionProvider, UserProvider>(
        builder: (context, provider, userProvider, child) {
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
                const SizedBox(height: 24),
                
                // Header with greeting and user name
                Row(
                  children: [
                    // صورة المستخدم (رمزية)
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final firstLetter = userProvider.userName.isNotEmpty 
                            ? userProvider.userName[0].toUpperCase()
                            : 'أ';
                        
                        return CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              return Text(
                                userProvider.welcomeMessage ?? 
                                'مرحباً، ${userProvider.userName}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM yyyy', 'ar').format(provider.selectedMonth),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Summary Cards Row
                Row(
                  children: [
                    // Income Card
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'الدخل',
                        amount: summary?.totalIncome ?? 0,
                        color: AppColors.incomeLight,
                        icon: Icons.arrow_downward_rounded,
                        iconColor: AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Commitments Card
                    Expanded(
                      child: _buildCommitmentCard(
                        title: 'الالتزامات',
                        amount: summary?.totalCommitments ?? 0,
                        percentage: commitmentPercentage,
                        color: AppColors.commitmentLight,
                        iconColor: AppColors.commitment,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Daily Expenses Card
                    Expanded(
                      child: _buildDailyExpenseCard(
                        title: 'المصروفات',
                        amount: summary?.totalExpenses ?? 0,
                        color: AppColors.expenseLight,
                        icon: Icons.show_chart_rounded,
                        iconColor: AppColors.expense,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // بطاقة التبرع عبر إحسان
                   InkWell(
                  onTap: () => _openEhsanPlatform(context),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Color(0xFF013F6D).withOpacity(0.2),
                  highlightColor: Color(0xFF013F6D).withOpacity(0.1),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF013F6D), // اللون الأزرق الداكن من الشعار
                          Color(0xFF188F7A), // اللون الأخضر من الشعار
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF013F6D).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // شعار إحسان SVG
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/ehsan-logo.svg', // المسار إلى ملف SVG
                            width: 32,
                            height: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التبرع عبر منصة إحسان',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ما نقص مالٌ من صدقة',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                
                // Remaining Balance Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkBrown.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المتبقي لك هذا الشهر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Balance with Circle Progress
                      Row(
                        children: [
                          // Amount
                          Text(
                            AppConstants.formatNumber(summary?.balance ?? 0),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ريال',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          // Circle Progress
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              children: [
                                CustomPaint(
                                  painter: CircleProgressPainter(
                                    progress: remainingPercentage,
                                    backgroundColor: AppColors.progressGray,
                                    progressColor: AppColors.progressGreen,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '${(remainingPercentage * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.progressGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'آخر العمليات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // الانتقال إلى شاشة السجل
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          'عرض الكل',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Transactions List
                if (recentTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkBrown.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد عمليات بعد',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
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
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.formatNumber(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ريال',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${AppConstants.formatNumber(amount)} ريال',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
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
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.formatNumber(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ريال',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            // يمكن إضافة تفاصيل إضافية عند النقر
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.city,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isExpense ? '' : '+'} ${AppConstants.formatMoney(transaction.amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExpense ? AppColors.textPrimary : AppColors.progressGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ريال',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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