// screens/add_transaction.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction;
  
  const AddTransactionSheet({super.key, this.transaction});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> with SingleTickerProviderStateMixin {
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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد التحكم في الرسوم المتحركة
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    if (widget.transaction != null) {
      _loadTransactionData();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final categories = provider.getCategoriesByType(_selectedType);
    final cities = provider.cities;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // المقبض
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // العنوان
                Text(
                  widget.transaction == null ? 'إضافة عملية جديدة' : 'تعديل العملية',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // اختيار النوع
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton(
                          'income', 
                          'دخل', 
                          Icons.arrow_downward_rounded,
                          Color(0xFFE8F5E9),
                          Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton(
                          'commitment', 
                          'التزام', 
                          Icons.event_repeat_rounded,
                          Color(0xFFFFEBEE),
                          Color(0xFFD32F2F),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton(
                          'expense', 
                          'مصروف', 
                          Icons.arrow_upward_rounded,
                          Color(0xFFE3F2FD),
                          Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // الوصف
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'الوصف',
                    hintText: 'مثال: راتب شهر يناير',
                    prefixIcon: const Icon(Icons.description_rounded, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الوصف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // المبلغ
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.grey),
                    suffixText: AppConstants.currencySymbol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال المبلغ';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'الرجاء إدخال مبلغ صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // الفئة
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'الفئة',
                    prefixIcon: const Icon(Icons.category_rounded, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: [
                    ...categories.map((cat) => DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name),
                    )),
                    const DropdownMenuItem(
                      value: '_add_new',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('إضافة فئة جديدة', style: TextStyle(color: AppColors.primary)),
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
                const SizedBox(height: 16),
                
                // المدينة
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'المدينة',
                    prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: [
                    ...cities.map((city) => DropdownMenuItem(
                      value: city.name,
                      child: Text(city.name),
                    )),
                    const DropdownMenuItem(
                      value: '_add_new',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('إضافة مدينة جديدة', style: TextStyle(color: AppColors.primary)),
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
                const SizedBox(height: 16),
                
                // التاريخ
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      prefixIcon: const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy/MM/dd').format(_selectedDate),
                        ),
                        const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // الملاحظات
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: const Icon(Icons.note_rounded, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                
                // خيار التكرار للالتزامات
                if (_selectedType == 'commitment') ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      title: const Text('التزام شهري متكرر', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('سيتم إضافته تلقائياً كل شهر'),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                      activeColor: AppColors.commitment,
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // الأزرار
                Row(
                  children: [
                    Expanded(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getButtonColor(),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: _getButtonColor().withOpacity(0.3),
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
                              : Text(
                                  widget.transaction == null ? 'إضافة' : 'حفظ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon, Color bgColor, Color iconColor) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: iconColor.withOpacity(0.3), width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? iconColor : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? iconColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (_selectedType) {
      case 'income':
        return const Color(0xFF2E7D32);
      case 'commitment':
        return const Color(0xFFD32F2F);
      case 'expense':
      default:
        return const Color(0xFF1976D2);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إضافة فئة جديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'اسم الفئة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => categoryName = value,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () async {
                        if (categoryName != null && categoryName!.isNotEmpty) {
                          final provider = context.read<TransactionProvider>();
                          final success = await provider.addCategory(categoryName!, _selectedType);
                          if (success && context.mounted) {
                            Navigator.pop(context, categoryName);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إضافة',
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

  Future<String?> _showAddCityDialog() async {
    String? cityName;
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إضافة مدينة جديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'اسم المدينة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => cityName = value,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () async {
                        if (cityName != null && cityName!.isNotEmpty) {
                          final provider = context.read<TransactionProvider>();
                          final success = await provider.addCity(cityName!);
                          if (success && context.mounted) {
                            Navigator.pop(context, cityName);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إضافة',
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final transaction = TransactionModel(
      id: widget.transaction?.id,
      type: _selectedType,
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      category: _selectedCategory!,
      city: _selectedCity!,
      date: _selectedDate,
      isRecurring: _isRecurring,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    final provider = context.read<TransactionProvider>();
    bool success;
    
    if (widget.transaction == null) {
      success = await provider.addTransaction(transaction);
    } else {
      success = await provider.updateTransaction(transaction);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transaction == null 
                ? 'تمت إضافة العملية بنجاح' 
                : 'تم تحديث العملية بنجاح',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}