import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

          return Column(
            children: [
              // شريط البحث والفلترة
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.background,
                child: Column(
                  children: [
                    const Text(
                      'السجل الكامل',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'بحث في العمليات...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
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
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return TransactionItem(
                            transaction: transactions[index],
                            onTap: () => _showTransactionOptions(
                              context,
                              transactions[index],
                              provider,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTransactionOptions(
    BuildContext context,
    TransactionModel transaction,
    TransactionProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
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
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('حذف', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد الحذف'),
                    content: const Text('هل أنت متأكد من حذف هذه العملية؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && transaction.id != null) {
                  await provider.deleteTransaction(transaction.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}