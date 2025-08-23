// providers/transaction_provider.dart

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For DateFormat

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // القوائم الرئيسية
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<CityModel> _cities = [];
  List<BudgetModel> _budgets = [];
  
  // الشهر المحدد
  DateTime _selectedMonth = DateTime.now();
  
  // الملخص الشهري
  MonthlySummary? _monthlySummary;
  
  // حالة التحميل
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  List<CityModel> get cities => _cities;
  List<BudgetModel> get budgets => _budgets;
  DateTime get selectedMonth => _selectedMonth;
  MonthlySummary? get monthlySummary => _monthlySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // تحميل البيانات الأولية
  Future<void> loadInitialData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // معالجة الالتزامات الشهرية
      await _db.processMonthlyCommitments(_selectedMonth);

      // تحميل البيانات
      await Future.wait([
        loadTransactions(),
        loadCategories(),
        loadCities(),
        loadBudgets(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'حدث خطأ في تحميل البيانات: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحميل المعاملات
  Future<void> loadTransactions() async {
    try {
      _transactions = await _db.getTransactionsByMonth(_selectedMonth);
      _monthlySummary = await _db.getMonthlySummary(_selectedMonth);
      notifyListeners();
    } catch (e) {
      _error = 'خطأ في تحميل المعاملات: $e';
      notifyListeners();
    }
  }

  // تحميل الفئات
  Future<void> loadCategories() async {
    try {
      final incomeCategories = await _db.getCategoriesByType('income');
      final expenseCategories = await _db.getCategoriesByType('expense');
      final commitmentCategories = await _db.getCategoriesByType('commitment');
      
      _categories = [
        ...incomeCategories,
        ...expenseCategories,
        ...commitmentCategories,
      ];
      notifyListeners();
    } catch (e) {
      _error = 'خطأ في تحميل الفئات: $e';
      notifyListeners();
    }
  }

  // تحميل المدن
  Future<void> loadCities() async {
    try {
      _cities = await _db.getAllCities();
      notifyListeners();
    } catch (e) {
      _error = 'خطأ في تحميل المدن: $e';
      notifyListeners();
    }
  }

  // تحميل الميزانيات
  Future<void> loadBudgets() async {
    try {
      _budgets = await _db.getAllBudgets();
      notifyListeners();
    } catch (e) {
      _error = 'خطأ في تحميل الميزانيات: $e';
      notifyListeners();
    }
  }

  // تغيير الشهر المحدد
  Future<void> changeMonth(DateTime month) async {
    _selectedMonth = month;
    await loadTransactions();
  }

  // إضافة معاملة جديدة
  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final id = await _db.insertTransaction(transaction);
      if (id > 0) {
        await loadTransactions();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'خطأ في إضافة المعاملة: $e';
      notifyListeners();
      return false;
    }
  }

  // تحديث معاملة
  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      final rowsAffected = await _db.updateTransaction(transaction);
      if (rowsAffected > 0) {
        await loadTransactions();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'خطأ في تحديث المعاملة: $e';
      notifyListeners();
      return false;
    }
  }

  // حذف معاملة
  Future<bool> deleteTransaction(int id) async {
    try {
      final rowsAffected = await _db.deleteTransaction(id);
      if (rowsAffected > 0) {
        await loadTransactions();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'خطأ في حذف المعاملة: $e';
      notifyListeners();
      return false;
    }
  }

  // إضافة فئة جديدة
  Future<bool> addCategory(String name, String type) async {
    try {
      final category = CategoryModel(
        name: name,
        type: type,
        isDefault: false,
      );
      
      final id = await _db.insertCategory(category);
      if (id > 0) {
        await loadCategories();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'خطأ في إضافة الفئة: $e';
      notifyListeners();
      return false;
    }
  }

  // إضافة مدينة جديدة
  Future<bool> addCity(String name) async {
    try {
      final city = CityModel(
        name: name,
        isDefault: false,
      );
      
      final id = await _db.insertCity(city);
      if (id > 0) {
        await loadCities();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'خطأ في إضافة المدينة: $e';
      notifyListeners();
      return false;
    }
  }

  // إضافة أو تحديث ميزانية
  Future<bool> saveBudget(BudgetModel budget) async {
    try {
      int result;
      if (budget.id == null) {
        result = await _db.insertBudget(budget);
      } else {
        result = await _db.updateBudget(budget);
      }
      
      if (result > 0) {
        await loadBudgets();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'خطأ في حفظ الميزانية: $e';
      notifyListeners();
      return false;
    }
  }

  // الحصول على الفئات حسب النوع
  List<CategoryModel> getCategoriesByType(String type) {
    return _categories.where((cat) => cat.type == type).toList();
  }

  // الحصول على ميزانية فئة معينة
  BudgetModel? getBudgetForCategory(String category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  // حساب نسبة الإنفاق من الميزانية
  double getCategoryBudgetProgress(String category) {
    final budget = getBudgetForCategory(category);
    if (budget == null) return 0;
    
    final spent = _monthlySummary?.expensesByCategory[category] ?? 0;
    if (budget.amount == 0) return 0;
    
    return (spent / budget.amount).clamp(0.0, 1.0);
  }

  // الحصول على آخر المعاملات
  List<TransactionModel> getRecentTransactions({int limit = 5}) {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sorted.take(limit).toList();
  }

  // البحث في المعاملات
  List<TransactionModel> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    
    final lowercaseQuery = query.toLowerCase();
    return _transactions.where((transaction) {
      return transaction.description.toLowerCase().contains(lowercaseQuery) ||
             transaction.category.toLowerCase().contains(lowercaseQuery) ||
             transaction.city.toLowerCase().contains(lowercaseQuery) ||
             transaction.notes?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
  }

  // فلترة المعاملات
  List<TransactionModel> filterTransactions({
    String? type,
    String? category,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _transactions.where((transaction) {
      if (type != null && transaction.type != type) return false;
      if (category != null && transaction.category != category) return false;
      if (city != null && transaction.city != city) return false;
      if (startDate != null && transaction.date.isBefore(startDate)) return false;
      if (endDate != null && transaction.date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  // تصفية الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}