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
// import '../utils/app_constants.dart'; // مؤقتاً حتى يتم إنشاء الملف

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// دالة مساعدة لتنسيق العملة
String _formatCurrency(double amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}م';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)}ك';
  } else {
    return amount.toStringAsFixed(0);
  }
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isInitialLoad = true;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ReportsScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // تحميل البيانات الأولية عندما يكون context جاهزاً
    if (_isInitialLoad) {
      _isInitialLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialData();
      });
    }
  }

  void _loadInitialData() {
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();
    
    // تحميل البيانات إذا لم تكن محملة بالفعل
    if (transactionProvider.transactions.isEmpty) {
      transactionProvider.loadInitialData();
    }
    
    if (userProvider.userName.isEmpty) {
      userProvider.loadUserData();
    }
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// في home_screen.dart - إضافة هذه التحديثات

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitialLoad = true;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // تحميل البيانات مباشرة عند أول عرض
    if (_isInitialLoad) {
      _isInitialLoad = false;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();
    
    // تحميل البيانات بشكل متزامن
    await Future.wait([
      transactionProvider.loadInitialData(),
      userProvider.loadUserData(),
    ]);
    
    // تحميل آخر العمليات فوراً من قاعدة البيانات
    await transactionProvider.loadRecentTransactionsImmediately(limit: 5);
    
    // تحديث الواجهة
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: Consumer2<TransactionProvider, UserProvider>(
          builder: (context, provider, userProvider, child) {
            if (provider.isLoading || userProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final summary = provider.monthlySummary;
            
            // استخدم الدالة المحدثة لجلب آخر العمليات
            final recentTransactions = provider.getRecentTransactions(limit: 3);
            
            // باقي الكود كما هو...
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الترحيب والأيقونات
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<UserProvider>(
                                builder: (context, userProvider, child) {
                                  final name = userProvider.userName.isNotEmpty 
                                      ? userProvider.userName 
                                      : 'مستخدم';
                                  return Text(
                                    'مرحباً، $name',
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
                    
                    // ترتيب جديد: الدخل في الأعلى
                    _buildSummaryCard(
                      title: 'الدخل',
                      amount: summary?.totalIncome ?? 0,
                      color: AppColors.incomeLight,
                      icon: Icons.arrow_downward_rounded,
                      iconColor: AppColors.income,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // الالتزامات والمصروفات في صف واحد
                    Row(
                      children: [
                        Expanded(
                          child: _buildCommitmentCard(
                            title: 'الالتزامات',
                            amount: summary?.totalCommitments ?? 0,
                            percentage: summary != null && summary.totalIncome > 0
                                ? (summary.totalCommitments / summary.totalIncome * 100)
                                : 0,
                            color: AppColors.commitmentLight,
                            iconColor: AppColors.commitment,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    
                    // بطاقة التبرع عبر إحسان مع الشعار الصحيح
                    InkWell(
                      onTap: () => _openEhsanPlatform(context),
                      borderRadius: BorderRadius.circular(20),
                      splashColor: const Color(0xFF013F6D).withOpacity(0.2),
                      highlightColor: const Color(0xFF013F6D).withOpacity(0.1),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF013F6D),
                              Color(0xFF188F7A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF013F6D).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // شعار إحسان - استخدام أيقونة بديلة إذا لم يكن SVG متوفراً
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism,
                                size: 30,
                                color: Color(0xFF013F6D),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ساهم في الخير',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'تبرع عبر منصة إحسان',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // الميزانية الشهرية
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الميزانية الشهرية',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'المتبقي من الدخل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(summary?.remainingBalance ?? 0),
                            style: TextStyle(
                              fontSize: 24,
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
                          const SizedBox(width: 16),
                          // Circle Progress
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(80, 80),
                                  painter: CircleProgressPainter(
                                    progress: summary != null && summary.totalIncome > 0
                                        ? ((summary.totalIncome - summary.totalExpenses - summary.totalCommitments) / summary.totalIncome).clamp(0.0, 1.0)
                                        : 0,
                                    backgroundColor: AppColors.progressGray,
                                    progressColor: AppColors.progressGreen,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      summary != null && summary.totalIncome > 0
                                          ? '${(((summary.totalIncome - summary.totalExpenses - summary.totalCommitments) / summary.totalIncome) * 100).clamp(0, 100).toStringAsFixed(0)}%'
                                          : '0%',
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
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // آخر العمليات - العنوان
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
                        if (recentTransactions.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // الانتقال مع الاحتفاظ بـ BottomNavigationBar
                              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                              homeState?._onTabTapped(2); // الانتقال إلى شاشة السجل
                            },
                            child: Text(
                              'عرض الكل',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // قائمة آخر العمليات - المحدثة
                    if (recentTransactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
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
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد عمليات حتى الآن',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ابدأ بإضافة أول عملية',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // عرض آخر العمليات مع التحديث التلقائي
                      ...recentTransactions.map((transaction) => TransactionItem(
                        key: ValueKey('transaction_${transaction.id}_${transaction.createdAt.millisecondsSinceEpoch}'), // مفتاح فريد للتحديث
                        transaction: transaction,
                        onTap: () => _showTransactionDetails(context, transaction),
                      )),
                      
                    const SizedBox(height: 100), // مساحة للزر العائم
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // باقي الدوال كما هي...
  void _showTransactionDetails(BuildContext context, TransactionModel transaction) {
    // عرض تفاصيل العملية
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تفاصيل العملية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوصف: ${transaction.description}'),
            Text('المبلغ: ${_formatCurrency(transaction.amount)}'),
            Text('الفئة: ${transaction.category}'),
            Text('المدينة: ${transaction.city}'),
            Text('التاريخ: ${DateFormat('yyyy/MM/dd').format(transaction.date)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // دالة لفتح منصة إحسان
  Future<void> _openEhsanPlatform(BuildContext context) async {
    String url;
    
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        url = 'https://play.google.com/store/apps/details?id=sa.gov.sdaia.ehsan';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        url = 'https://apps.apple.com/us/app/ehsan-إحسان/id1602515092';
      } else {
        url = 'https://ehsan.sa/';
      }
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح منصة إحسان')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء فتح المنصة')),
        );
      }
    }
  }

  // باقي دوال البناء...
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.event_repeat_rounded,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (percentage > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.progressGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 80 ? AppColors.error : AppColors.commitment,
              ),
              minHeight: 4,
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(0)}% من الدخل',
              style: TextStyle(
                fontSize: 11,
                color: percentage > 80 ? AppColors.error : AppColors.textLight,
              ),
            ),
          ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

// Transaction Item Widget
class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color backgroundColor;

    switch (transaction.type) {
      case 'income':
        icon = Icons.arrow_downward_rounded;
        iconColor = AppColors.income;
        backgroundColor = AppColors.incomeLight;
        break;
      case 'expense':
        icon = Icons.arrow_upward_rounded;
        iconColor = AppColors.expense;
        backgroundColor = AppColors.expenseLight;
        break;
      case 'commitment':
        icon = Icons.event_repeat_rounded;
        iconColor = AppColors.commitment;
        backgroundColor = AppColors.commitmentLight;
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey;
        backgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            transaction.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            transaction.city,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(transaction.amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: transaction.type == 'income' 
                            ? AppColors.income 
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd', 'ar').format(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
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
}