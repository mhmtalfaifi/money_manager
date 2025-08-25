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

class _HomeScreenState extends State<HomeScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
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
  bool get wantKeepAlive => true; // للحفاظ على حالة الشاشة

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    // تحميل البيانات الأولية بعد بناء الويدجت
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataSafely();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0, 
      end: 0.95
    ).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeInOut
      )
    );
  }

  Future<void> _loadInitialDataSafely() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      final userProvider = context.read<UserProvider>();
      
      // تحميل البيانات فقط إذا لم تكن محملة
      final futures = <Future>[];
      
      if (transactionProvider.transactions.isEmpty) {
        futures.add(transactionProvider.loadInitialData());
      }
      
      if (userProvider.userName.isEmpty) {
        futures.add(userProvider.loadUserData());
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات الأولية: $e');
      // يمكن إضافة معالجة إضافية للخطأ هنا
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return; // منع الضغط المتكرر
    
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0 
          ? _buildFloatingActionButton() 
          : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
            _buildNavItem(Icons.home_rounded, 'الرئيسية', 0),
            _buildNavItem(Icons.pie_chart_rounded, 'التقارير', 1),
            _buildNavItem(Icons.history_rounded, 'السجل', 2),
            _buildNavItem(Icons.settings_rounded, 'الإعدادات', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentIndex == index 
              ? AppColors.primary.withOpacity(0.1) 
              : Colors.transparent,
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: () {
          HapticFeedback.mediumImpact();
          _showAddTransaction();
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
          child: const Icon(
            Icons.add_rounded, 
            color: Colors.white, 
            size: 36,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTransaction() async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddTransactionSheet(),
      );
    } finally {
      _animationController.reverse();
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: Consumer2<TransactionProvider, UserProvider>(
          builder: (context, transactionProvider, userProvider, child) {
            
            if (_shouldShowLoading(transactionProvider, userProvider)) {
              return _buildLoadingState();
            }

            if (_hasError(transactionProvider, userProvider)) {
              return _buildErrorState(transactionProvider, userProvider);
            }

            return _buildMainContent(transactionProvider, userProvider);
          },
        ),
      ),
    );
  }

  bool _shouldShowLoading(TransactionProvider transactionProvider, UserProvider userProvider) {
    return transactionProvider.isLoading && transactionProvider.transactions.isEmpty;
  }

  bool _hasError(TransactionProvider transactionProvider, UserProvider userProvider) {
    return transactionProvider.error != null && transactionProvider.transactions.isEmpty;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TransactionProvider transactionProvider, UserProvider userProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transactionProvider.error ?? 'خطأ غير محدد',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(TransactionProvider transactionProvider, UserProvider userProvider) {
    final summary = transactionProvider.monthlySummary;
    final recentTransactions = transactionProvider.getRecentTransactions(limit: 3);
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userProvider, transactionProvider),
            const SizedBox(height: 32),
            _buildSummaryCards(summary),
            const SizedBox(height: 32),
            _buildEhsanCard(),
            const SizedBox(height: 32),
            _buildMonthlyBalance(summary),
            const SizedBox(height: 32),
            _buildRecentTransactionsSection(recentTransactions),
            const SizedBox(height: 100), // مساحة للزر العائم
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserProvider userProvider, TransactionProvider transactionProvider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'مرحباً، ${userProvider.userName.isNotEmpty ? userProvider.userName : 'مستخدم'}',
                  key: ValueKey(userProvider.userName),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM yyyy', 'ar').format(transactionProvider.selectedMonth),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(MonthlySummary? summary) {
    return Column(
      children: [
        // الدخل
        _buildSummaryCard(
          title: 'الدخل',
          amount: summary?.totalIncome ?? 0,
          color: AppColors.incomeLight,
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.income,
        ),
        
        const SizedBox(height: 12),
        
        // الالتزامات والمصروفات
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
              child: _buildExpenseCard(
                title: 'المصروفات',
                amount: summary?.totalExpenses ?? 0,
                color: AppColors.expenseLight,
                icon: Icons.show_chart_rounded,
                iconColor: AppColors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEhsanCard() {
    return InkWell(
      onTap: () => _openEhsanPlatform(context),
      borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildMonthlyBalance(MonthlySummary? summary) {
    final balance = summary?.remainingBalance ?? 0;
    final progress = summary != null && summary.totalIncome > 0
        ? (balance / summary.totalIncome).clamp(0.0, 1.0)
        : 0.0;

    return Container(
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
            child: const Icon(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(balance),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'ريال',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // دائرة التقدم
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: CircleProgressPainter(
                    progress: progress,
                    backgroundColor: AppColors.progressGray,
                    progressColor: AppColors.progressGreen,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
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
    );
  }

  Widget _buildRecentTransactionsSection(List<TransactionModel> recentTransactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'آخر العمليات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (recentTransactions.isNotEmpty)
              TextButton(
                onPressed: _navigateToHistory,
                child: const Text(
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
        
        if (recentTransactions.isEmpty)
          _buildEmptyTransactionsState()
        else
          ...recentTransactions.map((transaction) => 
            TransactionItem(
              key: ValueKey('transaction_${transaction.id}_${transaction.createdAt.millisecondsSinceEpoch}'),
              transaction: transaction,
              onTap: () => _showTransactionDetails(transaction),
              margin: const EdgeInsets.only(bottom: 12),
            )
          ),
      ],
    );
  }

  Widget _buildEmptyTransactionsState() {
    return Container(
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
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.textLight,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد عمليات حتى الآن',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
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
    );
  }

  // دوال مساعدة
  Future<void> _refreshData() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      final userProvider = context.read<UserProvider>();
      
      await Future.wait([
        transactionProvider.loadInitialData(),
        userProvider.loadUserData(),
      ]);
      
      await transactionProvider.loadRecentTransactionsImmediately(limit: 5);
    } catch (e) {
      debugPrint('خطأ في تحديث البيانات: $e');
    }
  }

  void _navigateToHistory() {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?._onTabTapped(2);
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تفاصيل العملية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الوصف', transaction.description),
            _buildDetailRow('المبلغ', _formatCurrency(transaction.amount)),
            _buildDetailRow('الفئة', transaction.category),
            _buildDetailRow('المدينة', transaction.city),
            _buildDetailRow('التاريخ', DateFormat('yyyy/MM/dd').format(transaction.date)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _openEhsanPlatform(BuildContext context) async {
    try {
      String url;
      
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
          _showErrorSnackBar('لا يمكن فتح منصة إحسان');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('حدث خطأ أثناء فتح المنصة');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // دوال بناء الكروت
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(amount),
                  style: const TextStyle(
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(
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

  Widget _buildExpenseCard({
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(
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

// Custom Painter للدائرة التقدمية
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
    
    // دائرة الخلفية
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius - 4, backgroundPaint);
    
    // قوس التقدم
    if (progress > 0) {
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
  }
  
  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.progressColor != progressColor;
  }
}

// Transaction Item Widget
class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final typeConfig = _getTransactionConfig(transaction.type);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
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
          onTap: onTap != null ? () {
            HapticFeedback.lightImpact();
            onTap!();
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeConfig.icon,
                    color: typeConfig.iconColor,
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
                        style: const TextStyle(
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              transaction.city,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      style: const TextStyle(
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

  _TransactionConfig _getTransactionConfig(String type) {
    switch (type) {
      case 'income':
        return _TransactionConfig(
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.income,
          backgroundColor: AppColors.incomeLight,
        );
      case 'expense':
        return _TransactionConfig(
          icon: Icons.arrow_upward_rounded,
          iconColor: AppColors.expense,
          backgroundColor: AppColors.expenseLight,
        );
      case 'commitment':
        return _TransactionConfig(
          icon: Icons.event_repeat_rounded,
          iconColor: AppColors.commitment,
          backgroundColor: AppColors.commitmentLight,
        );
      default:
        return _TransactionConfig(
          icon: Icons.help_outline,
          iconColor: Colors.grey,
          backgroundColor: Colors.grey.withOpacity(0.1),
        );
    }
  }
}

class _TransactionConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _TransactionConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}