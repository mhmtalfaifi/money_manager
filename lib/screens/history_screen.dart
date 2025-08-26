// screens/history_screen.dart - الإصدار المحسن

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_item.dart';
import '../widgets/empty_state.dart';
import '../utils/app_colors.dart';
import 'add_transaction.dart';
import '../models/transaction_model.dart';
import '../utils/app_constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  String? _filterType;
  String? _filterCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            var transactions = provider.transactions;
            
            // تطبيق البحث والفلترة
            if (_searchQuery.isNotEmpty) {
              transactions = provider.searchTransactions(_searchQuery);
            }
            
            if (_filterType != null || _filterCategory != null) {
              transactions = provider.filterTransactions(
                type: _filterType,
                category: _filterCategory,
              );
            }

            // تجميع المعاملات حسب التاريخ
            final Map<String, List<TransactionModel>> groupedTransactions = {};
            for (var transaction in transactions) {
              final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
              if (!groupedTransactions.containsKey(dateKey)) {
                groupedTransactions[dateKey] = [];
              }
              groupedTransactions[dateKey]!.add(transaction);
            }

            final sortedDates = groupedTransactions.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Column(
              children: [
                // الهيدر المحسن
                _buildHeader(provider, transactions),
                
                // شريط البحث والفلاتر
                _buildSearchAndFilters(provider),
                
                // المحتوى الرئيسي
                Expanded(
                  child: transactions.isEmpty
                      ? _buildEmptyState()
                      : _buildTransactionsList(groupedTransactions, sortedDates, provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(TransactionProvider provider, List<TransactionModel> transactions) {
    // حساب الإحصائيات السريعة للمعاملات المفلترة
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalCommitments = 0;
    
    for (var transaction in transactions) {
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'السجل الكامل',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transactions.length} معاملة',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: 20),
            // الإحصائيات السريعة
            Row(
              children: [
                if (totalIncome > 0)
                  Expanded(
                    child: _buildQuickStat(
                      'الدخل',
                      AppConstants.formatCompactMoney(totalIncome),
                      Icons.arrow_downward_rounded,
                      Colors.green,
                    ),
                  ),
                if (totalIncome > 0 && (totalExpenses > 0 || totalCommitments > 0))
                  const SizedBox(width: 12),
                if (totalExpenses > 0)
                  Expanded(
                    child: _buildQuickStat(
                      'المصروفات',
                      AppConstants.formatCompactMoney(totalExpenses),
                      Icons.arrow_upward_rounded,
                      Colors.red,
                    ),
                  ),
                if (totalExpenses > 0 && totalCommitments > 0)
                  const SizedBox(width: 12),
                if (totalCommitments > 0)
                  Expanded(
                    child: _buildQuickStat(
                      'الالتزامات',
                      AppConstants.formatCompactMoney(totalCommitments),
                      Icons.event_repeat_rounded,
                      Colors.orange,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(TransactionProvider provider) {
    return Column(
      children: [
        // شريط البحث والأزرار
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  // شريط البحث
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _searchQuery.isNotEmpty 
                              ? AppColors.primary 
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'ابحث في العمليات...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(
                            Icons.search_rounded, 
                            color: _searchQuery.isNotEmpty 
                                ? AppColors.primary 
                                : Colors.grey.shade400,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded, 
                                    color: Colors.grey.shade400,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر الفلاتر
                  Container(
                    decoration: BoxDecoration(
                      color: _showFilters 
                          ? AppColors.primary 
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showFilters 
                            ? AppColors.primary 
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                        if (_showFilters) {
                          _filterAnimationController.forward();
                        } else {
                          _filterAnimationController.reverse();
                        }
                      },
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _showFilters ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر مسح الفلاتر
                  if (_filterType != null || _filterCategory != null)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _filterType = null;
                            _filterCategory = null;
                          });
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // الفلاتر المتحركة
        AnimatedBuilder(
          animation: _filterAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _filterAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: _buildFilters(provider),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilters(TransactionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تصفية حسب:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        // فلاتر النوع
        const Text(
          'النوع:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'الكل',
                selected: _filterType == null,
                onTap: () => setState(() => _filterType = null),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'الدخل',
                selected: _filterType == 'income',
                icon: Icons.arrow_downward_rounded,
                color: AppColors.income,
                onTap: () => setState(() {
                  _filterType = 'income';
                  _filterCategory = null;
                }),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'المصروفات',
                selected: _filterType == 'expense',
                icon: Icons.arrow_upward_rounded,
                color: AppColors.expense,
                onTap: () => setState(() {
                  _filterType = 'expense';
                  _filterCategory = null;
                }),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'الالتزامات',
                selected: _filterType == 'commitment',
                icon: Icons.event_repeat_rounded,
                color: AppColors.commitment,
                onTap: () => setState(() {
                  _filterType = 'commitment';
                  _filterCategory = null;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (color ?? AppColors.primary) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? (color ?? AppColors.primary) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : (color ?? AppColors.primary),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : (color ?? AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    Map<String, List<TransactionModel>> groupedTransactions,
    List<String> sortedDates,
    TransactionProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateTransactions = groupedTransactions[date]!;
        final totalAmount = dateTransactions.fold<double>(
          0, 
          (sum, transaction) => sum + (
            transaction.type == 'income' 
              ? transaction.amount 
              : -transaction.amount
          )
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // تاريخ المجموعة مع الإحصائيات
            Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateHeader(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateTransactions.length} معاملة',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppConstants.formatMoney(totalAmount.abs()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: totalAmount >= 0 
                              ? AppColors.income 
                              : AppColors.expense,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (totalAmount >= 0 
                              ? AppColors.income 
                              : AppColors.expense).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          totalAmount >= 0 ? 'ربح' : 'خسارة',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: totalAmount >= 0 
                                ? AppColors.income 
                                : AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // قائمة المعاملات لهذا التاريخ
            ...dateTransactions.map((transaction) => 
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: TransactionItem(
                  transaction: transaction,
                  onTap: () => _showTransactionOptions(
                    context,
                    transaction,
                    provider,
                  ),
                ),
              )
            ),
            
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String title = 'لا توجد عمليات';
    String subtitle = 'ابدأ بإضافة أول عملية';
    
    if (_searchQuery.isNotEmpty) {
      title = 'لا توجد نتائج';
      subtitle = 'جرب كلمات بحث مختلفة';
    } else if (_filterType != null) {
      title = 'لا توجد عمليات';
      subtitle = 'لا توجد عمليات من هذا النوع';
    }

    return EmptyState(
      icon: _searchQuery.isNotEmpty 
          ? Icons.search_off_rounded 
          : Icons.receipt_long_rounded,
      title: title,
      subtitle: subtitle,
    );
  }

  String _formatDateHeader(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return 'اليوم';
    } else if (date.isAtSameMomentAs(yesterday)) {
      return 'أمس';
    } else {
      return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
    }
  }

  void _showTransactionOptions(
    BuildContext context,
    TransactionModel transaction,
    TransactionProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // المقبض
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // تفاصيل المعاملة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getTransactionColor(transaction.type)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppConstants.getTypeText(transaction.type),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getTransactionColor(transaction.type),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppConstants.formatMoney(transaction.amount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTransactionColor(transaction.type),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // الخيارات
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'تعديل',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddTransactionSheet(
                      transaction: transaction,
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'حذف',
                  style: TextStyle(
                    fontWeight: FontWeight.w500, 
                    color: AppColors.error,
                  ),
                ),
                onTap: () => _confirmDelete(context, transaction, provider),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionModel transaction,
    TransactionProvider provider,
  ) async {
    Navigator.pop(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 24,
            ),
            SizedBox(width: 12),
            Text('تأكيد الحذف'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه العملية؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true && transaction.id != null) {
      await provider.deleteTransaction(transaction.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('تم حذف العملية بنجاح'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}