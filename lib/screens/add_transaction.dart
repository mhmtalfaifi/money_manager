// screens/add_transaction.dart - الإصدار المحسن

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/input_formatters.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction;
  final String? initialType; // إضافة النوع الافتراضي
  
  const AddTransactionSheet({
    super.key, 
    this.transaction,
    this.initialType,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'expense';
  String? _selectedCategory;
  String? _selectedCity;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeForm();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  void _initializeForm() {
    // إذا كان هناك معاملة للتعديل
    if (widget.transaction != null) {
      _loadTransactionData();
    } 
    // إذا كان هناك نوع افتراضي
    else if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  void _loadTransactionData() {
    final transaction = widget.transaction!;
    _selectedType = transaction.type;
    _descriptionController.text = transaction.description;
    _amountController.text = transaction.amount.toString();
    _selectedCategory = transaction.category;
    _selectedCity = transaction.city;
    _selectedDate = transaction.date;
    _isRecurring = transaction.isRecurring;
    _notesController.text = transaction.notes ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTypeColor().withOpacity(0.1),
            _getTypeColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // المقبض
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getTypeColor().withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction == null 
                          ? 'إضافة ${AppConstants.getTypeText(_selectedType)}'
                          : 'تعديل ${AppConstants.getTypeText(_selectedType)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(),
                      ),
                    ),
                    Text(
                      widget.transaction == null
                          ? 'أضف معاملة جديدة للنظام'
                          : 'قم بتعديل تفاصيل المعاملة',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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

  Widget _buildForm() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final categories = provider.getCategoriesByType(_selectedType);
        final cities = provider.cities;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              
              // اختيار النوع
              _buildTypeSelector(),
              const SizedBox(height: 24),
              
              // الوصف
              _buildDescriptionField(),
              const SizedBox(height: 20),
              
              // المبلغ
              _buildAmountField(),
              const SizedBox(height: 20),
              
              // الفئة والمدينة
              Row(
                children: [
                  Expanded(child: _buildCategoryField(categories, provider)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCityField(cities, provider)),
                ],
              ),
              const SizedBox(height: 20),
              
              // التاريخ والملاحظات
              Row(
                children: [
                  Expanded(child: _buildDateField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildNotesField()),
                ],
              ),
              
              // خيار التكرار للالتزامات
              if (_selectedType == 'commitment') ...[
                const SizedBox(height: 20),
                _buildRecurringOption(),
              ],
              
              const SizedBox(height: 32),
              
              // الأزرار
              _buildActionButtons(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              'income', 
              'دخل', 
              Icons.arrow_downward_rounded,
              AppColors.income,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTypeButton(
              'expense', 
              'مصروف', 
              Icons.arrow_upward_rounded,
              AppColors.expense,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTypeButton(
              'commitment', 
              'التزام', 
              Icons.event_repeat_rounded,
              AppColors.commitment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedType = type;
          _selectedCategory = null; // إعادة تعيين الفئة عند تغيير النوع
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: color.withOpacity(0.3), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected 
                    ? color.withOpacity(0.2) 
                    : AppColors.textLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: 'وصف المعاملة',
          hintText: 'مثال: راتب شهر يناير، فاتورة الكهرباء',
          prefixIcon: Icon(
            Icons.description_rounded, 
            color: _getTypeColor(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _getTypeColor(), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'الرجاء إدخال وصف المعاملة';
          }
          if (value.trim().length < 2) {
            return 'الوصف يجب أن يكون على الأقل حرفين';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          EnglishNumbersOnlyFormatter(),
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          labelText: 'المبلغ',
          hintText: '0.00',
          prefixIcon: Icon(
            Icons.attach_money_rounded, 
            color: _getTypeColor(),
          ),
          suffixText: AppConstants.currencySymbol,
          suffixStyle: TextStyle(
            color: _getTypeColor(),
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _getTypeColor(), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'الرجاء إدخال المبلغ';
          }
          final amount = double.tryParse(value);
          if (amount == null || amount <= 0) {
            return 'الرجاء إدخال مبلغ صحيح';
          }
          if (amount > AppConstants.maxAmount) {
            return 'المبلغ يتجاوز الحد الأقصى المسموح';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryField(List<CategoryModel> categories, TransactionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'الفئة',
          prefixIcon: Icon(
            Icons.category_rounded, 
            color: _getTypeColor(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _getTypeColor(), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        icon: Icon(Icons.arrow_drop_down_rounded, color: _getTypeColor()),
        items: [
          ...categories.map((cat) => DropdownMenuItem(
            value: cat.name,
            child: Row(
              children: [
                Text(
                  AppConstants.categoryIcons[cat.name] ?? '📝',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(cat.name),
              ],
            ),
          )),
          DropdownMenuItem(
            value: '_add_new',
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: _getTypeColor()),
                const SizedBox(width: 8),
                Text(
                  'إضافة فئة جديدة', 
                  style: TextStyle(color: _getTypeColor()),
                ),
              ],
            ),
          ),
        ],
        onChanged: (value) async {
          if (value == '_add_new') {
            final newCategory = await _showAddCategoryDialog();
            if (newCategory != null) {
              setState(() {
                _selectedCategory = newCategory;
              });
            }
          } else {
            setState(() {
              _selectedCategory = value;
            });
          }
        },
        validator: (value) {
          if (value == null || value == '_add_new') {
            return 'الرجاء اختيار الفئة';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCityField(List<CityModel> cities, TransactionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        decoration: InputDecoration(
          labelText: 'المدينة',
          prefixIcon: Icon(
            Icons.location_city_rounded, 
            color: _getTypeColor(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _getTypeColor(), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        icon: Icon(Icons.arrow_drop_down_rounded, color: _getTypeColor()),
        items: [
          ...cities.map((city) => DropdownMenuItem(
            value: city.name,
            child: Text(city.name),
          )),
          DropdownMenuItem(
            value: '_add_new',
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: _getTypeColor()),
                const SizedBox(width: 8),
                Text(
                  'إضافة مدينة جديدة', 
                  style: TextStyle(color: _getTypeColor()),
                ),
              ],
            ),
          ),
        ],
        onChanged: (value) async {
          if (value == '_add_new') {
            final newCity = await _showAddCityDialog();
            if (newCity != null) {
              setState(() {
                _selectedCity = newCity;
              });
            }
          } else {
            setState(() {
              _selectedCity = value;
            });
          }
        },
        validator: (value) {
          if (value == null || value == '_add_new') {
            return 'الرجاء اختيار المدينة';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'التاريخ',
            prefixIcon: Icon(
              Icons.calendar_today_rounded, 
              color: _getTypeColor(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConstants.formatDate(_selectedDate),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.calendar_month_rounded, 
                size: 20, 
                color: _getTypeColor().withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'ملاحظات (اختياري)',
          hintText: 'أضف أي ملاحظات إضافية',
          prefixIcon: Icon(
            Icons.note_rounded, 
            color: _getTypeColor(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _getTypeColor(), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildRecurringOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.commitment.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.commitment.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.autorenew_rounded,
              color: AppColors.commitment,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'التزام شهري متكرر',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سيتم إضافته تلقائياً كل شهر',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Switch.adaptive(
              value: _isRecurring,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _isRecurring = value;
                });
              },
              activeColor: AppColors.commitment,
              activeTrackColor: AppColors.commitment.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: _getTypeColor().withOpacity(0.5)),
            ),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: _getTypeColor(),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTypeColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              shadowColor: _getTypeColor().withOpacity(0.4),
              disabledBackgroundColor: _getTypeColor().withOpacity(0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.transaction == null ? Icons.add : Icons.save,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.transaction == null ? 'إضافة' : 'حفظ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // دوال مساعدة للحصول على لون ورمز النوع
  Color _getTypeColor() {
    switch (_selectedType) {
      case 'income':
        return AppColors.income;
      case 'commitment':
        return AppColors.commitment;
      case 'expense':
      default:
        return AppColors.expense;
    }
  }

  IconData _getTypeIcon() {
    switch (_selectedType) {
      case 'income':
        return Icons.arrow_downward_rounded;
      case 'commitment':
        return Icons.event_repeat_rounded;
      case 'expense':
      default:
        return Icons.arrow_upward_rounded;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _getTypeColor(),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<String?> _showAddCategoryDialog() async {
    String? categoryName;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.category_rounded,
                color: _getTypeColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'فئة جديدة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTypeColor(),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم الفئة',
                hintText: 'مثال: مواصلات، طعام، ترفيه',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _getTypeColor()),
                ),
                prefixIcon: Icon(
                  Icons.label_rounded,
                  color: _getTypeColor(),
                ),
              ),
              onChanged: (value) => categoryName = value,
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  final provider = context.read<TransactionProvider>();
                  final success = await provider.addCategory(value.trim(), _selectedType, context: context);
                  if (success && context.mounted) {
                    Navigator.pop(context, value.trim());
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (categoryName != null && categoryName!.trim().isNotEmpty) {
                final provider = context.read<TransactionProvider>();
                final success = await provider.addCategory(categoryName!.trim(), _selectedType, context: context);
                if (success && context.mounted) {
                  Navigator.pop(context, categoryName!.trim());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTypeColor(),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showAddCityDialog() async {
    String? cityName;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_city_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'مدينة جديدة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم المدينة',
                hintText: 'مثال: الرياض، جدة، الدمام',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                prefixIcon: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                ),
              ),
              onChanged: (value) => cityName = value,
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  final provider = context.read<TransactionProvider>();
                  final success = await provider.addCity(value.trim(), context: context);
                  if (success && context.mounted) {
                    Navigator.pop(context, value.trim());
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (cityName != null && cityName!.trim().isNotEmpty) {
                final provider = context.read<TransactionProvider>();
                final success = await provider.addCity(cityName!.trim(), context: context);
                if (success && context.mounted) {
                  Navigator.pop(context, cityName!.trim());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final transaction = TransactionModel(
        id: widget.transaction?.id,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        city: _selectedCity!,
        date: _selectedDate,
        isRecurring: _isRecurring,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      );

      final provider = context.read<TransactionProvider>();
      bool success;
      
      if (widget.transaction == null) {
        success = await provider.addTransaction(transaction, context: context);
      } else {
        success = await provider.updateTransaction(transaction, context: context);
      }

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.transaction == null 
                      ? 'تمت إضافة المعاملة بنجاح' 
                      : 'تم تحديث المعاملة بنجاح',
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('حدث خطأ: ${e.toString()}'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}