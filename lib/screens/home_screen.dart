import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
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
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
    final recentTransactions = transactionProvider.getRecentTransactions(limit: 5);
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userProvider, transactionProvider),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildFinancialSummary(summary),
            const SizedBox(height: 24),
            _buildMonthlyOverview(summary),
            const SizedBox(height: 24),
            _buildEhsanCard(),
            const SizedBox(height: 24),
            _buildRecentTransactionsSection(recentTransactions),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserProvider userProvider, TransactionProvider transactionProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
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
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMMM yyyy', 'ar').format(transactionProvider.selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة ذكية لأموالك',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.arrow_downward_rounded,
                  label: 'إضافة دخل',
                  color: AppColors.income,
                  onTap: () => _showAddTransactionType('income'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.arrow_upward_rounded,
                  label: 'إضافة مصروف',
                  color: AppColors.expense,
                  onTap: () => _showAddTransactionType('expense'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.event_repeat_rounded,
                  label: 'إضافة التزام',
                  color: AppColors.commitment,
                  onTap: () => _showAddTransactionType('commitment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(MonthlySummary? summary) {
    if (summary == null) return const SizedBox.shrink();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الملخص المالي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'إجمالي الدخل',
                  amount: summary.totalIncome,
                  icon: Icons.trending_up_rounded,
                  color: AppColors.income,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildSummaryItem(
                  title: 'إجمالي الصرف',
                  amount: summary.totalExpenses + summary.totalCommitments,
                  icon: Icons.trending_down_rounded,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: summary.netIncome >= 0
                    ? [AppColors.income.withOpacity(0.1), AppColors.income.withOpacity(0.05)]
                    : [AppColors.error.withOpacity(0.1), AppColors.error.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: summary.netIncome >= 0 
                    ? AppColors.income.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: summary.netIncome >= 0 
                        ? AppColors.income.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    summary.netIncome >= 0 
                        ? Icons.account_balance_wallet_rounded
                        : Icons.warning_rounded,
                    color: summary.netIncome >= 0 ? AppColors.income : AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.netIncome >= 0 ? 'صافي الربح' : 'العجز المالي',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.formatMoney(summary.netIncome.abs()),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: summary.netIncome >= 0 ? AppColors.income : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary.totalIncome > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: summary.netIncome >= 0 
                          ? AppColors.income.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(summary.netIncome / summary.totalIncome * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: summary.netIncome >= 0 ? AppColors.income : AppColors.error,
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

  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          AppConstants.formatCompactMoney(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMonthlyOverview(MonthlySummary? summary) {
    if (summary == null) return const SizedBox.shrink();

    final savingsRate = summary.savingsRate;
    final expenseRate = summary.expenseRate;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'نظرة شهرية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('MMM yyyy', 'ar').format(summary.month),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewMetric(
                  title: 'معدل الإدخار',
                  value: '${savingsRate.toStringAsFixed(1)}%',
                  icon: Icons.savings_rounded,
                  color: AppColors.success,
                  progress: savingsRate / 100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewMetric(
                  title: 'معدل الإنفاق',
                  value: '${expenseRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: expenseRate > 80 ? AppColors.error : AppColors.warning,
                  progress: expenseRate / 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  title: 'متوسط يومي',
                  value: AppConstants.formatMoney((summary.totalExpenses + summary.totalCommitments) / 30),
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailMetric(
                  title: 'المتبقي',
                  value: AppConstants.formatCompactMoney(summary.remainingBalance),
                  icon: Icons.account_balance_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
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

  Widget _buildEhsanCard() {
    return InkWell(
      onTap: () => _openEhsanPlatform(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
                borderRadius: BorderRadius.circular(16),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'تبرع عبر منصة إحسان الرسمية',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'وزارة الموارد البشرية والتنمية الاجتماعية',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
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
              TextButton.icon(
                onPressed: _navigateToHistory,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                label: const Text('عرض الكل'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 14,
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

  void _showAddTransactionType(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        initialType: type,
      ),
    );
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
            _buildDetailRow('المبلغ', AppConstants.formatMoney(transaction.amount)),
            _buildDetailRow('الفئة', transaction.category),
            _buildDetailRow('المدينة', transaction.city),
            _buildDetailRow('التاريخ', DateFormat('yyyy/MM/dd').format(transaction.date)),
            _buildDetailRow('النوع', AppConstants.getTypeText(transaction.type)),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeConfig.iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppConstants.getTypeText(transaction.type),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: typeConfig.iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            transaction.category,
                            style: const TextStyle(
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
                      AppConstants.formatCompactMoney(transaction.amount),
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