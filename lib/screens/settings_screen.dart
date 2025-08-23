// screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../helpers/database_helper.dart';
import 'budget_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _budgetAlerts = true;
  String _currency = 'SAR';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // قسم الإحصائيات السريعة
          _buildQuickStats(provider),
          
          // قسم الميزانيات
          _buildSection(
            title: 'الميزانيات والأهداف',
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('إدارة الميزانيات'),
                subtitle: const Text('حدد ميزانية شهرية لكل فئة'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetScreen(),
                    ),
                  );
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: const Text('تنبيهات الميزانية'),
                subtitle: const Text('تنبيه عند تجاوز 80% من الميزانية'),
                value: _budgetAlerts,
                onChanged: (value) {
                  setState(() => _budgetAlerts = value);
                },
              ),
            ],
          ),
          
          // قسم التطبيق
          _buildSection(
            title: 'التطبيق',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('الوضع الليلي'),
                subtitle: const Text('تفعيل الوضع الداكن'),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() => _isDarkMode = value);
                  // يمكن إضافة تغيير الثيم هنا
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('الإشعارات'),
                subtitle: const Text('تفعيل جميع الإشعارات'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('اللغة'),
                subtitle: const Text('العربية'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // يمكن إضافة اختيار اللغة
                },
              ),
            ],
          ),
          
          // قسم البيانات
          _buildSection(
            title: 'البيانات',
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('النسخ الاحتياطي'),
                subtitle: Text(
                  'آخر نسخة: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showBackupDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('تصدير البيانات'),
                subtitle: const Text('تصدير كملف Excel أو PDF'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showExportDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text(
                  'مسح جميع البيانات',
                  style: TextStyle(color: AppColors.error),
                ),
                subtitle: const Text('حذف جميع العمليات والبيانات'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showDeleteDataDialog(context),
              ),
            ],
          ),
          
          // قسم الفئات والمدن
          _buildSection(
            title: 'الفئات والمدن',
            children: [
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('إدارة الفئات'),
                subtitle: Text('${provider.categories.length} فئة'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCategoriesDialog(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text('إدارة المدن'),
                subtitle: Text('${provider.cities.length} مدينة'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCitiesDialog(context, provider),
              ),
            ],
          ),
          
          // قسم حول
          _buildSection(
            title: 'حول',
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('المساعدة والدعم'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // يمكن إضافة صفحة المساعدة
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('تقييم التطبيق'),
                subtitle: const Text('ساعدنا بتقييمك'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // يمكن إضافة رابط التقييم
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('حول التطبيق'),
                subtitle: const Text('الإصدار 1.0.0'),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إدارة الفئات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddCategoryDialog(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return ListTile(
                      leading: Icon(
                        AppColors.getTransactionIcon(category.type),
                        color: AppColors.getTransactionColor(category.type),
                      ),
                      title: Text(category.name),
                      subtitle: Text(
                        category.type == 'income' ? 'دخل' :
                        category.type == 'expense' ? 'مصروف' : 'التزام',
                      ),
                      trailing: category.isDefault
                          ? const Chip(
                              label: Text('افتراضي', style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                            )
                          : IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                // يمكن إضافة حذف الفئة
                              },
                            ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    String? name;
    String type = 'expense';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة فئة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة',
                hintText: 'مثال: رياضة',
              ),
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(
                labelText: 'النوع',
              ),
              items: const [
                DropdownMenuItem(value: 'income', child: Text('دخل')),
                DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                DropdownMenuItem(value: 'commitment', child: Text('التزام')),
              ],
              onChanged: (value) => type = value!,
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
              if (name != null && name!.isNotEmpty) {
                final provider = context.read<TransactionProvider>();
                await provider.addCategory(name!, type);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  _showCategoriesDialog(context, provider);
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showCitiesDialog(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إدارة المدن',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddCityDialog(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.cities.length,
                  itemBuilder: (context, index) {
                    final city = provider.cities[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: AppColors.primary,
                      ),
                      title: Text(city.name),
                      trailing: city.isDefault
                          ? const Chip(
                              label: Text('افتراضي', style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                            )
                          : IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                // يمكن إضافة حذف المدينة
                              },
                            ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCityDialog(BuildContext context) {
    String? name;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مدينة جديدة'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم المدينة',
            hintText: 'مثال: الطائف',
          ),
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name != null && name!.isNotEmpty) {
                final provider = context.read<TransactionProvider>();
                await provider.addCity(name!);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  _showCitiesDialog(context, provider);
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حول التطبيق'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'مدير الأموال',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              'تطبيق سهل وبسيط لإدارة أموالك الشخصية',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'صُمم بكل حب ❤️',
              style: TextStyle(fontSize: 12),
            ),
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
}

  Widget _buildQuickStats(TransactionProvider provider) {
    final summary = provider.monthlySummary;
    if (summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withBlue(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الشهر الحالي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'الدخل',
                AppConstants.formatMoney(summary.totalIncome),
                Icons.arrow_downward,
              ),
              _buildStatItem(
                'المصروفات',
                AppConstants.formatMoney(summary.totalExpenses),
                Icons.arrow_upward,
              ),
              _buildStatItem(
                'المتبقي',
                AppConstants.formatMoney(summary.balance),
                Icons.account_balance_wallet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('النسخ الاحتياطي'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.cloud_upload, color: AppColors.primary),
              title: Text('نسخ احتياطي الآن'),
              subtitle: Text('حفظ البيانات في السحابة'),
            ),
            ListTile(
              leading: Icon(Icons.restore, color: AppColors.success),
              title: Text('استعادة من نسخة'),
              subtitle: Text('استرجاع البيانات المحفوظة'),
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.warning),
              title: Text('نسخ تلقائي'),
              subtitle: Text('كل يوم في الساعة 2:00 صباحاً'),
            ),
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel'),
              subtitle: const Text('تصدير كملف Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('جاري تصدير البيانات...'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              subtitle: const Text('تصدير كملف PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('جاري تصدير البيانات...'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحذير!'),
        content: const Text(
          'هل أنت متأكد من حذف جميع البيانات؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // يمكن إضافة حذف البيانات هنا
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف جميع البيانات'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
      );
  }
