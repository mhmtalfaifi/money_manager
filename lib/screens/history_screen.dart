import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_item.dart';
import '../widgets/empty_state.dart';
import '../utils/app_colors.dart';
import 'add_transaction.dart';
import '../models/transaction_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filterType;
  String? _filterCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                // شريط البحث والفلترة
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
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
                      const Text(
                        'السجل الكامل',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // شريط البحث
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'ابحث في العمليات...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // أزرار الفلترة
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'الكل',
                              selected: _filterType == null && _filterCategory == null,
                              onTap: () => setState(() {
                                _filterType = null;
                                _filterCategory = null;
                              }),
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
                  ),
                ),
                
                // قائمة العمليات
                Expanded(
                  child: transactions.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'لا توجد عمليات',
                          subtitle: _searchQuery.isNotEmpty 
                              ? 'لا توجد نتائج للبحث'
                              : 'ابدأ بإضافة أول عملية',
                        )
                      : ListView.builder(
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
                                // تاريخ المجموعة
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        _formatDateHeader(date),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        AppConstants.formatNumber(totalAmount.abs()),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: totalAmount >= 0 
                                              ? AppColors.income 
                                              : AppColors.expense,
                                        ),
                                      ),
                                      Text(
                                        ' ${AppConstants.currencySymbol}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: totalAmount >= 0 
                                              ? AppColors.income 
                                              : AppColors.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // قائمة المعاملات لهذا التاريخ
                                ...dateTransactions.map((transaction) => 
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: TransactionItem(
                                      transaction: transaction,
                                      onTap: () => _showTransactionOptions(
                                        context,
                                        transaction,
                                        provider,
                                      ),
                                    ),
                                  )
                                ).toList(),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
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
          color: selected ? color ?? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color ?? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : color ?? AppColors.primary,
              ),
            if (icon != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : color ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
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
      return DateFormat('EEEE, d MMMM yyyy', 'ar').format(date);
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
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text('تعديل', style: TextStyle(fontWeight: FontWeight.w500)),
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
                  child: Icon(
                    Icons.delete_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'تأكيد الحذف',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'هل أنت متأكد من حذف هذه العملية؟',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('إلغاء'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'حذف',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  
                  if (confirm == true && transaction.id != null) {
                    await provider.deleteTransaction(transaction.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم حذف العملية بنجاح'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}