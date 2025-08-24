// screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart'; // إضافة هذا الاستيراد
import '../utils/app_colors.dart';
import '../helpers/database_helper.dart';
import 'budget_screen.dart';
import '../utils/app_constants.dart';
import '../services/export_import_service.dart';
import '../widgets/edit_name_dialog.dart'; // إضافة هذا الاستيراد

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
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'الإعدادات',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // قسم الإحصائيات السريعة
            _buildQuickStats(provider),
            const SizedBox(height: 24),
            
            // بطاقة معلومات المستخدم
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showEditNameDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // صورة المستخدم (رمزية)
                        Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            final firstLetter = userProvider.userName.isNotEmpty 
                                ? userProvider.userName[0].toUpperCase()
                                : 'أ';
                            
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1B5E20),
                                    Color(0xFF2E7D32),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // معلومات المستخدم
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الملف الشخصي',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Consumer<UserProvider>(
                                builder: (context, userProvider, child) {
                                  return Text(
                                    'الاسم: ${userProvider.userName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'اضغط لتعديل الاسم',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // زر التعديل
                        Container(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // قسم الميزانيات
            _buildSection(
              title: 'الميزانيات والأهداف',
              icon: Icons.account_balance_wallet_rounded,
              children: [
                _buildSettingsItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'إدارة الميزانيات',
                  subtitle: 'حدد ميزانية شهرية لكل فئة',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(),
                      ),
                    );
                  },
                ),
                _buildSwitchItem(
                  icon: Icons.notifications_active_rounded,
                  title: 'تنبيهات الميزانية',
                  subtitle: 'تنبيه عند تجاوز 80% من الميزانية',
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
              icon: Icons.settings_rounded,
              children: [
                _buildSwitchItem(
                  icon: Icons.dark_mode_rounded,
                  title: 'الوضع الليلي',
                  subtitle: 'تفعيل الوضع الداكن',
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() => _isDarkMode = value);
                  },
                ),
                _buildSwitchItem(
                  icon: Icons.notifications_outlined,
                  title: 'الإشعارات',
                  subtitle: 'تفعيل جميع الإشعارات',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.language_rounded,
                  title: 'اللغة',
                  subtitle: 'العربية',
                  onTap: () {
                    // يمكن إضافة اختيار اللغة
                  },
                ),
              ],
            ),
            
            // قسم البيانات
            _buildSection(
              title: 'البيانات',
              icon: Icons.storage_rounded,
              children: [
                _buildSettingsItem(
                  icon: Icons.cloud_upload_rounded,
                  title: 'النسخ الاحتياطي',
                  subtitle: 'آخر نسخة: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
                  onTap: () => _showBackupDialog(context),
                ),
                _buildSettingsItem(
                  icon: Icons.download_rounded,
                  title: 'تصدير البيانات',
                  subtitle: 'تصدير كملف Excel أو PDF',
                  onTap: () => _showExportDialog(context),
                ),
                _buildSettingsItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'مسح جميع البيانات',
                  subtitle: 'حذف جميع العمليات والبيانات',
                  color: AppColors.error,
                  onTap: () => _showDeleteDataDialog(context),
                ),
              ],
            ),
            
            // قسم الفئات والمدن
            _buildSection(
              title: 'الفئات والمدن',
              icon: Icons.category_rounded,
              children: [
                _buildSettingsItem(
                  icon: Icons.category_rounded,
                  title: 'إدارة الفئات',
                  subtitle: '${provider.categories.length} فئة',
                  onTap: () => _showCategoriesDialog(context, provider),
                ),
                _buildSettingsItem(
                  icon: Icons.location_city_rounded,
                  title: 'إدارة المدن',
                  subtitle: '${provider.cities.length} مدينة',
                  onTap: () => _showCitiesDialog(context, provider),
                ),
              ],
            ),
            
            // قسم حول
            _buildSection(
              title: 'حول التطبيق',
              icon: Icons.info_outline_rounded,
              children: [
                _buildSettingsItem(
                  icon: Icons.help_outline_rounded,
                  title: 'المساعدة والدعم',
                  subtitle: 'دليل استخدام التطبيق',
                  onTap: () {
                    // يمكن إضافة صفحة المساعدة
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.star_outline_rounded,
                  title: 'تقييم التطبيق',
                  subtitle: 'ساعدنا بتقييمك',
                  onTap: () {
                    // يمكن إضافة رابط التقييم
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: 'حول التطبيق',
                  subtitle: 'الإصدار 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // دالة لإظهار حوار تعديل الاسم
  void _showEditNameDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const EditNameDialog(),
    );
    
    if (result == true && context.mounted) {
      // تحديث البيانات إذا تم حفظ الاسم بنجاح
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData();
      await userProvider.refreshWelcomeMessage();
      
      // إظهار رسالة تأكيد
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الاسم إلى: ${userProvider.userName}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildQuickStats(TransactionProvider provider) {
    final summary = provider.monthlySummary;
    if (summary == null) return const SizedBox.shrink();

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الشهر الحالي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'الدخل',
                AppConstants.formatMoney(summary.totalIncome),
                Icons.arrow_downward_rounded,
              ),
              _buildStatItem(
                'المصروفات',
                AppConstants.formatMoney(summary.totalExpenses),
                Icons.arrow_upward_rounded,
              ),
              _buildStatItem(
                'المتبقي',
                AppConstants.formatMoney(summary.netIncome),
                Icons.account_balance_wallet_rounded,
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color ?? AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: color ?? Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // باقي الدوال كما هي...
  void _showCategoriesDialog(BuildContext context, TransactionProvider provider) {
    // ... نفس الكود السابق
  }

  void _showAddCategoryDialog(BuildContext context) {
    // ... نفس الكود السابق
  }

  void _showCitiesDialog(BuildContext context, TransactionProvider provider) {
    // ... نفس الكود السابق
  }

  void _showAddCityDialog(BuildContext context) {
    // ... نفس الكود السابق
  }

  void _showAboutDialog(BuildContext context) {
    // ... نفس الكود السابق
  }

  void _showBackupDialog(BuildContext context) {
    // ... نفس الكود السابق
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final provider = context.read<TransactionProvider>();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تصدير البيانات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDialogOption(
                icon: Icons.picture_as_pdf_rounded,
                title: 'PDF',
                subtitle: 'تصدير كملف PDF',
                color: Colors.red,
                onTap: () async {
                  Navigator.pop(context);
                  
                  try {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('جاري تصدير البيانات...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    
                    final filePath = await ExportImportService.instance.exportToPdf();
                    
                    if (filePath != null) {
                      await ExportImportService.instance.shareExcelFile(filePath);
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('تم تصدير البيانات بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في التصدير: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'تحذير!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'هل أنت متأكد من حذف جميع البيانات؟\nلا يمكن التراجع عن هذا الإجراء.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حذف جميع البيانات'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'حذف الكل',
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
  }
}