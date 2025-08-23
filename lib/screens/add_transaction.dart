// screens/add_transaction.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';


class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction;
  
  const AddTransactionSheet({super.key, this.transaction});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
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

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _loadTransactionData();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final categories = provider.getCategoriesByType(_selectedType);
    final cities = provider.cities;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // العنوان
                Text(
                  widget.transaction == null ? 'إضافة عملية جديدة' : 'تعديل العملية',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // اختيار النوع
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'income',
                      label: Text('دخل'),
                      icon: Icon(Icons.arrow_downward_rounded),
                    ),
                    ButtonSegment(
                      value: 'commitment',
                      label: Text('التزام'),
                      icon: Icon(Icons.event_repeat_rounded),
                    ),
                    ButtonSegment(
                      value: 'expense',
                      label: Text('مصروف'),
                      icon: Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (value) {
                    setState(() {
                      _selectedType = value.first;
                      _selectedCategory = null; // إعادة تعيين الفئة
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.getTransactionColor(_selectedType).withOpacity(0.2);
                      }
                      return null;
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                
                // الوصف
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'الوصف',
                    hintText: 'مثال: راتب شهر يناير',
                    prefixIcon: const Icon(Icons.description_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    suffixText: AppConstants.currencySymbol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    prefixIcon: const Icon(Icons.category_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    ...categories.map((cat) => DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name),
                    )),
                    const DropdownMenuItem(
                      value: '_add_new',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text('إضافة فئة جديدة'),
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
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    ...cities.map((city) => DropdownMenuItem(
                      value: city.name,
                      child: Text(city.name),
                    )),
                    const DropdownMenuItem(
                      value: '_add_new',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text('إضافة مدينة جديدة'),
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
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DateFormat('yyyy/MM/dd').format(_selectedDate),
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
                    prefixIcon: const Icon(Icons.note_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // خيار التكرار للالتزامات
                if (_selectedType == 'commitment') ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('التزام شهري متكرر'),
                    subtitle: const Text('سيتم إضافته تلقائياً كل شهر'),
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                      });
                    },
                    activeColor: AppColors.commitment,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // الأزرار
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
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getTransactionColor(_selectedType),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                style: const TextStyle(color: Colors.white),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'SA'),
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
        title: const Text('إضافة فئة جديدة'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'اسم الفئة',
          ),
          onChanged: (value) => categoryName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (categoryName != null && categoryName!.isNotEmpty) {
                final provider = context.read<TransactionProvider>();
                final success = await provider.addCategory(categoryName!, _selectedType);
                if (success && context.mounted) {
                  Navigator.pop(context, categoryName);
                }
              }
            },
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
        title: const Text('إضافة مدينة جديدة'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'اسم المدينة',
          ),
          onChanged: (value) => cityName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (cityName != null && cityName!.isNotEmpty) {
                final provider = context.read<TransactionProvider>();
                final success = await provider.addCity(cityName!);
                if (success && context.mounted) {
                  Navigator.pop(context, cityName);
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
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
        ),
      );
    }
  }
}