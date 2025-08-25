// screens/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_state.dart';
import '../utils/app_constants.dart';
import '../utils/input_formatters.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E9), // خلفية بيج فاتح
      appBar: AppBar(
        title: const Text(
          'الميزانيات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF473D33), // بني داكن
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F2E9), // خلفية بيج فاتح
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFC5D300), // أخضر فاتح
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
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
              icon: Icons.account_balance_wallet_rounded,
              title: 'لا توجد فئات',
              subtitle: 'أضف فئات أولاً من شاشة إضافة العمليات',
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان الصفحة
                const Text(
                  'إدارة الميزانيات الشهرية',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF473D33), // بني داكن
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تابع مصروفاتك والتزم بميزانيتك',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF473D33).withOpacity(0.6), // بني داكن مع شفافية
                  ),
                ),
                const SizedBox(height: 24),
                
                // قائمة الميزانيات
                Expanded(
                  child: ListView.builder(
                    itemCount: allCategories.length,
                    itemBuilder: (context, index) {
                      final category = allCategories[index];
                      final budget = provider.getBudgetForCategory(category.name);
                      final summary = provider.monthlySummary;
                      final spent = summary?.expensesByCategory[category.name] ?? 0;
                      final progress = budget != null && budget.amount > 0
                          ? (spent / budget.amount).clamp(0.0, 1.5)
                          : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF473D33).withOpacity(0.05), // بني داكن مع شفافية
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: budget != null
                                ? () => _showEditBudgetDialog(context, category.name, budget)
                                : () => _showAddBudgetDialog(context, category.name),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // أيقونة الفئة
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
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // معلومات الفئة
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              category.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF473D33), // بني داكن
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              category.type == 'expense' ? 'مصروف' : 'التزام',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: const Color(0xFF473D33).withOpacity(0.6), // بني داكن مع شفافية
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // الميزانية
                                      if (budget != null) ...[
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              AppConstants.formatMoney(budget.amount),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF473D33), // بني داكن
                                              ),
                                            ),
                                            Text(
                                              'الميزانية',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: const Color(0xFF473D33).withOpacity(0.6), // بني داكن مع شفافية
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC5D300).withOpacity(0.1), // أخضر فاتح مع شفافية
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'تحديد ميزانية',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFC5D300), // أخضر فاتح
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  
                                  if (budget != null) ...[
                                    const SizedBox(height: 20),
                                    
                                    // شريط التقدم
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'المصروف: ${AppConstants.formatMoney(spent)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: const Color(0xFF473D33).withOpacity(0.6), // بني داكن مع شفافية
                                              ),
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
                                        
                                        // شريط التقدم
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: progress > 1 ? 1 : progress,
                                            backgroundColor: const Color(0xFF473D33).withOpacity(0.1), // بني داكن مع شفافية
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _getProgressColor(progress),
                                            ),
                                            minHeight: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // المتبقي
                                        Text(
                                          'المتبقي: ${AppConstants.formatMoney((budget.amount - spent).clamp(0, double.infinity))}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(0xFF473D33).withOpacity(0.6), // بني داكن مع شفافية
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // التحذيرات
                                    if (progress > 0.8) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: progress > 1
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              progress > 1
                                                  ? Icons.error_outline_rounded
                                                  : Icons.warning_amber_rounded,
                                              size: 20,
                                              color: progress > 1
                                                  ? Colors.red
                                                  : Colors.orange,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                progress > 1
                                                    ? 'تجاوزت الميزانية بمبلغ ${AppConstants.formatMoney(spent - budget.amount)}'
                                                    : 'اقتربت من حد الميزانية',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: progress > 1
                                                      ? Colors.red
                                                      : Colors.orange,
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
                        ),
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

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'expense':
        return Colors.red;
      case 'commitment':
        return Colors.blue;
      default:
        return const Color(0xFF473D33); // بني داكن
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'expense':
        return Icons.shopping_cart_rounded;
      case 'commitment':
        return Icons.event_repeat_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress > 1) return Colors.red;
    if (progress > 0.8) return Colors.orange;
    if (progress > 0.6) return const Color(0xFFC5D300); // أخضر فاتح
    return Colors.green;
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
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2E9), // خلفية بيج فاتح
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تحديد ميزانية جديدة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF473D33), // بني داكن
                  ),
                ),
                const SizedBox(height: 20),
                
                if (categoryName == null) ...[
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'الفئة',
                      labelStyle: const TextStyle(color: Color(0xFF473D33)), // بني داكن
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: categories.map((cat) => DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name, style: const TextStyle(color: Color(0xFF473D33))), // بني داكن
                    )).toList(),
                    onChanged: (value) => selectedCategory = value,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: const Color(0xFFC5D300), // أخضر فاتح
                        ),
                        const SizedBox(width: 12),
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF473D33), // بني داكن
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    EnglishNumbersOnlyFormatter(),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'المبلغ الشهري',
                    labelStyle: const TextStyle(color: Color(0xFF473D33)), // بني داكن
                    hintText: '0.00',
                    suffixText: AppConstants.currencySymbol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFF473D33)), // بني داكن
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(color: Color(0xFF473D33)), // بني داكن
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
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
                                SnackBar(
                                  content: const Text('تم تحديد الميزانية بنجاح'),
                                  backgroundColor: const Color(0xFFC5D300), // أخضر فاتح
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5D300), // أخضر فاتح
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حفظ',
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
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2E9), // خلفية بيج فاتح
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعديل الميزانية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF473D33), // بني داكن
                  ),
                ),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        color: const Color(0xFFC5D300), // أخضر فاتح
                      ),
                      const SizedBox(width: 12),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF473D33), // بني داكن
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    EnglishNumbersOnlyFormatter(),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'المبلغ الشهري',
                    labelStyle: const TextStyle(color: Color(0xFF473D33)), // بني داكن
                    hintText: '0.00',
                    suffixText: AppConstants.currencySymbol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFF473D33)), // بني داكن
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(color: Color(0xFF473D33)), // بني داكن
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
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
                              SnackBar(
                                content: const Text('تم حذف الميزانية'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          'حذف',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
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
                                SnackBar(
                                  content: const Text('تم تحديث الميزانية بنجاح'),
                                  backgroundColor: const Color(0xFFC5D300), // أخضر فاتح
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5D300), // أخضر فاتح
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حفظ',
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
      ),
    );
  }
}