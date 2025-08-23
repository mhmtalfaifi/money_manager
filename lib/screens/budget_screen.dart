// screens/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_state.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الميزانيات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final categories = provider.getCategoriesByType('expense');
          final commitmentCategories = provider.getCategoriesByType('commitment');
          final allCategories = [...categories, ...commitmentCategories];
          
          if (allCategories.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet,
              title: 'لا توجد فئات',
              subtitle: 'أضف فئات أولاً من شاشة إضافة العمليات',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final category = allCategories[index];
              final budget = provider.getBudgetForCategory(category.name);
              final summary = provider.monthlySummary;
              final spent = summary?.expensesByCategory[category.name] ?? 0;
              final progress = budget != null && budget.amount > 0
                  ? (spent / budget.amount).clamp(0.0, 1.5)
                  : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: budget != null
                      ? () => _showEditBudgetDialog(context, category.name, budget)
                      : () => _showAddBudgetDialog(context, category.name),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category.type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(category.type),
                                color: _getCategoryColor(category.type),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    category.type == 'expense' ? 'مصروف' : 'التزام',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (budget != null) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.formatMoney(budget.amount),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'الميزانية',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'تحديد ميزانية',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (budget != null) ...[
                          const SizedBox(height: 16),
                          // شريط التقدم
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'المصروف: ${AppConstants.formatMoney(spent)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getProgressColor(progress),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress > 1 ? 1 : progress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(progress),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'المتبقي: ${AppConstants.formatMoney((budget.amount - spent).clamp(0, double.infinity))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // التحذيرات
                          if (progress > 0.8) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: progress > 1
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    progress > 1
                                        ? Icons.error_outline
                                        : Icons.warning_amber_rounded,
                                    size: 16,
                                    color: progress > 1
                                        ? AppColors.error
                                        : AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      progress > 1
                                          ? 'تجاوزت الميزانية بمبلغ ${AppConstants.formatMoney(spent - budget.amount)}'
                                          : 'اقتربت من حد الميزانية',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: progress > 1
                                            ? AppColors.error
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'expense':
        return AppColors.expense;
      case 'commitment':
        return AppColors.commitment;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'expense':
        return Icons.shopping_cart;
      case 'commitment':
        return Icons.event_repeat;
      default:
        return Icons.category;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress > 1) return AppColors.error;
    if (progress > 0.8) return AppColors.warning;
    if (progress > 0.6) return Colors.orange;
    return AppColors.success;
  }

  Future<void> _showAddBudgetDialog(BuildContext context, [String? categoryName]) async {
    final provider = context.read<TransactionProvider>();
    final categories = [
      ...provider.getCategoriesByType('expense'),
      ...provider.getCategoriesByType('commitment'),
    ];

    String? selectedCategory = categoryName;
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تحديد ميزانية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (categoryName == null) ...[
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((cat) => DropdownMenuItem(
                  value: cat.name,
                  child: Text(cat.name),
                )).toList(),
                onChanged: (value) => selectedCategory = value,
              ),
              const SizedBox(height: 16),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.category,
                  color: AppColors.primary,
                ),
                title: Text(categoryName),
                subtitle: const Text('الفئة المحددة'),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'المبلغ الشهري',
                hintText: '0.00',
                suffixText: AppConstants.currencySymbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0 && selectedCategory != null) {
                final budget = BudgetModel(
                  category: selectedCategory!,
                  amount: amount,
                  startDate: DateTime.now(),
                );
                
                await provider.saveBudget(budget);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديد الميزانية بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBudgetDialog(
    BuildContext context,
    String categoryName,
    BudgetModel budget,
  ) async {
    final provider = context.read<TransactionProvider>();
    final amountController = TextEditingController(
      text: budget.amount.toString(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الميزانية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.category,
                color: AppColors.primary,
              ),
              title: Text(categoryName),
              subtitle: const Text('الفئة'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'المبلغ الشهري',
                hintText: '0.00',
                suffixText: AppConstants.currencySymbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              // حذف الميزانية
              final updatedBudget = BudgetModel(
                id: budget.id,
                category: categoryName,
                amount: 0,
                startDate: budget.startDate,
              );
              
              await provider.saveBudget(updatedBudget);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الميزانية'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final updatedBudget = BudgetModel(
                  id: budget.id,
                  category: categoryName,
                  amount: amount,
                  startDate: budget.startDate,
                );
                
                await provider.saveBudget(updatedBudget);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث الميزانية بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}