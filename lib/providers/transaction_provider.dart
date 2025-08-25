// providers/transaction_provider.dart - الإصلاحات الجذرية

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/app_error.dart';
import '../helpers/database_helper.dart';
import '../services/error_handler_service.dart';
import '../services/cache_service.dart';
import '../services/memory_manager_service.dart';
import 'package:intl/intl.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  final CacheService _cache = CacheService();
  final MemoryManagerService _memoryManager = MemoryManagerService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // البيانات
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<CityModel> _cities = [];
  List<BudgetModel> _budgets = [];
  
  // إضافة متغير خاص لآخر العمليات مع التحديث الفوري
  List<TransactionModel> _recentTransactions = [];
  bool _recentTransactionsNeedsUpdate = true;
  
  // الحالة
  DateTime _selectedMonth = DateTime.now();
  MonthlySummary? _monthlySummary;
  bool _isLoading = false;
  String? _error;
  
  // التحكم في الأداء
  bool _enableCaching = true;
  int _batchSize = 50;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  List<CityModel> get cities => _cities;
  List<BudgetModel> get budgets => _budgets;
  DateTime get selectedMonth => _selectedMonth;
  MonthlySummary? get monthlySummary => _monthlySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== تحديث دالة آخر العمليات ==========

  /// الحصول على آخر العمليات مع التحديث الفوري
  List<TransactionModel> getRecentTransactions({int limit = 5}) {
    // إذا كان يحتاج تحديث أو الليست فارغة، قم بتحديثها
    if (_recentTransactionsNeedsUpdate || _recentTransactions.isEmpty) {
      _updateRecentTransactionsCache(limit);
    }
    
    // إرجاع العدد المطلوب
    return _recentTransactions.take(limit).toList();
  }

  /// تحديث كاش آخر العمليات
  void _updateRecentTransactionsCache(int limit) {
    try {
      // جلب كل المعاملات وترتيبها حسب تاريخ الإنشاء (الأحدث أولاً)
      final allTransactions = List<TransactionModel>.from(_transactions);
      allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // أخذ العدد المطلوب
      _recentTransactions = allTransactions.take(limit + 10).toList(); // أخذ عدد أكثر للاحتياط
      _recentTransactionsNeedsUpdate = false;
      
      // تحديث الكاش العادي أيضاً
      final cacheKey = 'recent_$limit';
      _cache.set(cacheKey, _recentTransactions.take(limit).toList(), 
                ttl: const Duration(minutes: 1));
                
    } catch (e) {
      _errorHandler.logSimpleError('خطأ في تحديث آخر العمليات: $e');
    }
  }

  /// إجبار تحديث آخر العمليات
  void _forceUpdateRecentTransactions() {
    _recentTransactionsNeedsUpdate = true;
    _updateRecentTransactionsCache(10); // تحديث مع رقم كبير للاحتياط
  }

  // ========== تحديث دالة إضافة المعاملة ==========

  /// إضافة معاملة جديدة مع التحديث الفوري
  Future<bool> addTransaction(TransactionModel transaction, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        // التحقق من صحة البيانات
        _validateTransaction(transaction);
        
        // إدراج في قاعدة البيانات
        final id = await _db.insertTransaction(transaction);
        
        if (id > 0) {
          // إنشاء المعاملة الجديدة مع الـ id
          final newTransaction = transaction.copyWith(id: id);
          
          // تحديث القائمة المحلية فوراً
          _transactions.insert(0, newTransaction); // إدراج في المقدمة
          
          // إجبار تحديث آخر العمليات
          _forceUpdateRecentTransactions();
          
          // تحديث الكاش
          _invalidateAllRelatedCache();
          
          // إعادة حساب الملخص
          await calculateMonthlySummary();
          
          // إشعار الواجهة بالتحديث فوراً
          notifyListeners();
          
          // التحقق من تجاوز الميزانية (في الخلفية)
          if (transaction.type == 'expense') {
            _checkBudgetAlert(transaction.category, context);
          }
          
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري إضافة المعاملة...',
      successMessage: 'تم إضافة المعاملة بنجاح',
      context: context,
    ) ?? false;
  }

  /// تحديث معاملة مع التحديث الفوري
  Future<bool> updateTransaction(TransactionModel transaction, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        _validateTransaction(transaction);
        
        final rowsAffected = await _db.updateTransaction(transaction);
        
        if (rowsAffected > 0) {
          // تحديث القائمة المحلية
          final index = _transactions.indexWhere((t) => t.id == transaction.id);
          if (index != -1) {
            _transactions[index] = transaction;
          }
          
          // إجبار تحديث آخر العمليات
          _forceUpdateRecentTransactions();
          
          // تحديث الكاش
          _invalidateAllRelatedCache();
          
          // إعادة حساب الملخص
          await calculateMonthlySummary();
          
          // إشعار فوري
          notifyListeners();
          
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري تحديث المعاملة...',
      successMessage: 'تم تحديث المعاملة بنجاح',
      context: context,
    ) ?? false;
  }

  /// حذف معاملة مع التحديث الفوري
  Future<bool> deleteTransaction(int id, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        final rowsAffected = await _db.deleteTransaction(id);
        
        if (rowsAffected > 0) {
          // إزالة من القائمة المحلية
          _transactions.removeWhere((t) => t.id == id);
          
          // إجبار تحديث آخر العمليات
          _forceUpdateRecentTransactions();
          
          // تحديث الكاش
          _invalidateAllRelatedCache();
          
          // إعادة حساب الملخص
          await calculateMonthlySummary();
          
          // إشعار فوري
          notifyListeners();
          
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري حذف المعاملة...',
      successMessage: 'تم حذف المعاملة بنجاح',
      context: context,
    ) ?? false;
  }

  // ========== تحديث دوال الكاش ==========

  /// إلغاء جميع الكاش المرتبط بالمعاملات
  void _invalidateAllRelatedCache() {
    _cache.invalidateRelatedCache('transactions');
    _cache.invalidateRelatedCache('recent');
    _cache.invalidateRelatedCache('monthly');
    
    // إلغاء كاش آخر العمليات
    for (int i = 1; i <= 10; i++) {
      _cache.remove('recent_$i');
    }
  }

  // ========== تحديث دالة التحميل الأولي ==========

  /// تحميل البيانات الأولية مع معالجة الأخطاء
  Future<void> loadInitialData() async {
    if (_isLoading) return; // منع التحميل المتعدد
    
    _setLoading(true);
    
    try {
      // تحميل البيانات بشكل متوازي
      await Future.wait([
        _loadTransactions(),
        _loadBudgets(),
        _loadCategories(),
      ]);
      
      // إجبار تحديث آخر العمليات
      _forceUpdateRecentTransactions();
      
      // حساب الملخص فوراً
      await calculateMonthlySummary();
      
      // إشعار الواجهة بالتحديث
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحميل البيانات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل المعاملات مع التخزين المؤقت
  Future<void> _loadTransactions() async {
    await _loadTransactionsWithCache();
  }

  Future<void> _loadBudgets() async {
    await _loadBudgetsWithCache();
  }

  Future<void> _loadCategories() async {
    await _loadCategoriesWithCache();
  }

  // ========== دالة تحميل سريع لآخر العمليات ==========

  /// تحميل آخر العمليات بشكل فوري من قاعدة البيانات
  Future<List<TransactionModel>> loadRecentTransactionsImmediately({int limit = 5}) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      
      final transactions = maps.map((map) => TransactionModel.fromMap(map)).toList();
      
      // تحديث الكاش المحلي
      _recentTransactions = transactions;
      _recentTransactionsNeedsUpdate = false;
      
      // تحديث الكاش العام
      _cache.set('recent_$limit', transactions, ttl: const Duration(minutes: 1));
      
      return transactions;
    } catch (e) {
      _errorHandler.logSimpleError('خطأ في تحميل آخر العمليات: $e');
      return _recentTransactions.take(limit).toList();
    }
  }

  // ========== باقي الدوال كما هي ==========

  /// حساب الملخص الشهري
  Future<void> calculateMonthlySummary() async {
    try {
      final monthTransactions = _transactions.where((t) => 
        t.date.year == _selectedMonth.year && 
        t.date.month == _selectedMonth.month
      ).toList();
      
      double totalIncome = 0;
      double totalExpenses = 0;
      double totalCommitments = 0;
      Map<String, double> expensesByCategory = {};
      Map<String, double> expensesByCity = {};

      for (final transaction in monthTransactions) {
        switch (transaction.type) {
          case 'income':
            totalIncome += transaction.amount;
            break;
          case 'expense':
            totalExpenses += transaction.amount;
            expensesByCategory[transaction.category] = 
              (expensesByCategory[transaction.category] ?? 0) + transaction.amount;
            expensesByCity[transaction.city] = 
              (expensesByCity[transaction.city] ?? 0) + transaction.amount;
            break;
          case 'commitment':
            totalCommitments += transaction.amount;
            break;
        }
      }

      _monthlySummary = MonthlySummary(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        totalCommitments: totalCommitments,
        month: DateTime(_selectedMonth.year, _selectedMonth.month),
        expensesByCategory: expensesByCategory,
        expensesByCity: expensesByCity,
      );
    } catch (e) {
      _errorHandler.logSimpleError('خطأ في حساب الملخص الشهري: $e');
    }
  }

  /// تحميل المعاملات مع التخزين المؤقت
  Future<void> _loadTransactionsWithCache() async {
    if (_enableCaching) {
      final cached = _cache.getCachedTransactions('monthly_${_selectedMonth.year}_${_selectedMonth.month}');
      if (cached != null) {
        _transactions = cached;
        return;
      }
    }
    
    final transactions = await _errorHandler.handleDatabaseOperation(
      () => _db.getTransactionsByMonth(_selectedMonth),
      errorMessage: 'خطأ في تحميل المعاملات',
    );
    
    if (transactions != null) {
      _transactions = transactions;
      if (_enableCaching) {
        _cache.cacheTransactions('monthly_${_selectedMonth.year}_${_selectedMonth.month}', transactions);
      }
    }
  }

  /// تحميل الفئات مع التخزين المؤقت
  Future<void> _loadCategoriesWithCache() async {
    final allCategories = <CategoryModel>[];
    
    for (String type in ['income', 'expense', 'commitment']) {
      if (_enableCaching) {
        final cached = _cache.getCachedCategories(type);
        if (cached != null) {
          allCategories.addAll(cached);
          continue;
        }
      }
      
      final categories = await _errorHandler.handleDatabaseOperation(
        () => _db.getCategoriesByType(type),
        errorMessage: 'خطأ في تحميل فئات $type',
      );
      
      if (categories != null) {
        allCategories.addAll(categories);
        if (_enableCaching) {
          _cache.cacheCategories(type, categories);
        }
      }
    }
    
    _categories = allCategories;
  }

  /// تحميل الميزانيات
  Future<void> _loadBudgetsWithCache() async {
    final budgets = await _errorHandler.handleDatabaseOperation(
      () => _db.getAllBudgets(),
      errorMessage: 'خطأ في تحميل الميزانيات',
    );
    
    if (budgets != null) {
      _budgets = budgets;
    }
  }

  // ========== دوال مساعدة ==========

  /// تنفيذ عملية مع معالجة شاملة للأخطاء
  Future<T?> _performOperation<T>({
    required Future<T> Function() operation,
    String? loadingMessage,
    String? successMessage,
    BuildContext? context,
  }) async {
    try {
      _setLoading(true, loadingMessage);
      
      final result = await operation();
      
      _setLoading(false);
      _clearError();
      
      if (successMessage != null && context != null) {
        _showSuccessMessage(context, successMessage);
      }
      
      return result;
    } catch (e) {
      final error = AppError(
        type: ErrorType.database,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
      
      _errorHandler.logError(error);
      _setError(e.toString());
      _setLoading(false);
      
      if (context != null) {
        _errorHandler.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
      
      return null;
    }
  }

  void _setLoading(bool loading, [String? message]) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// التحقق من صحة المعاملة
  void _validateTransaction(TransactionModel transaction) {
    if (transaction.description.trim().isEmpty) {
      throw AppError.validation('الوصف مطلوب');
    }
    
    if (transaction.amount <= 0) {
      throw AppError.validation('المبلغ يجب أن يكون أكبر من صفر');
    }
    
    if (transaction.category.trim().isEmpty) {
      throw AppError.validation('الفئة مطلوبة');
    }
    
    if (transaction.city.trim().isEmpty) {
      throw AppError.validation('المدينة مطلوبة');
    }
  }

  /// التحقق من تجاوز الميزانية وإرسال تنبيه
  Future<void> _checkBudgetAlert(String category, BuildContext? context) async {
    try {
      final budget = getBudgetForCategory(category);
      if (budget == null) return;
      
      final progress = getCategoryBudgetProgress(category);
      
      if (progress >= 0.8) {
        if (context != null) {
          final percentage = progress * 100;
          String message = percentage >= 100
              ? 'تجاوزت ميزانية "$category" بنسبة ${(percentage - 100).toStringAsFixed(0)}%'
              : 'اقتربت من حد ميزانية "$category" (${percentage.toStringAsFixed(0)}%)';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    percentage >= 100 ? Icons.error : Icons.warning,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: percentage >= 100 ? Colors.red[600] : Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      _errorHandler.logSimpleError('خطأ في فحص الميزانية: $e');
    }
  }

  // باقي الدوال المساعدة...
  List<CategoryModel> getCategoriesByType(String type) {
    return _categories.where((cat) => cat.type == type).toList();
  }

  BudgetModel? getBudgetForCategory(String category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  double getCategoryBudgetProgress(String category) {
    final budget = getBudgetForCategory(category);
    if (budget == null) return 0;
    
    final spent = _monthlySummary?.expensesByCategory[category] ?? 0;
    if (budget.amount == 0) return 0;
    
    return (spent / budget.amount).clamp(0.0, 2.0);
  }

  /// تغيير الشهر المحدد مع إعادة تحميل البيانات
  Future<void> changeMonth(DateTime month, {BuildContext? context}) async {
    if (_selectedMonth.year == month.year && _selectedMonth.month == month.month) {
      return;
    }
    
    await _performOperation(
      operation: () async {
        _selectedMonth = month;
        await _loadTransactionsWithCache();
        await calculateMonthlySummary();
        
        // تحديث آخر العمليات أيضاً
        _forceUpdateRecentTransactions();
      },
      loadingMessage: 'جاري تحميل بيانات ${DateFormat('MMMM yyyy', 'ar').format(month)}...',
      context: context,
    );
  }

  // ========== الدوال المفقودة ==========

  /// إضافة فئة جديدة
  Future<bool> addCategory(String name, String type, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        final category = CategoryModel(name: name, type: type);
        final id = await _db.insertCategory(category);
        
        if (id > 0) {
          _cache.invalidateRelatedCache('categories');
          await _loadCategoriesWithCache();
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري إضافة الفئة...',
      successMessage: 'تم إضافة الفئة بنجاح',
      context: context,
    ) ?? false;
  }

  /// إضافة مدينة جديدة
  Future<bool> addCity(String name, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        final city = CityModel(name: name);
        final id = await _db.insertCity(city);
        
        if (id > 0) {
          await _loadCitiesWithCache();
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري إضافة المدينة...',
      successMessage: 'تم إضافة المدينة بنجاح',
      context: context,
    ) ?? false;
  }

  /// حفظ ميزانية مع معالجة الأخطاء
  Future<bool> saveBudget(BudgetModel budget, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        int result;
        if (budget.id == null) {
          result = await _db.insertBudget(budget);
        } else {
          result = await _db.updateBudget(budget);
        }
        
        if (result > 0) {
          _cache.invalidateRelatedCache('budgets');
          await _loadBudgetsWithCache();
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري حفظ الميزانية...',
      successMessage: 'تم حفظ الميزانية بنجاح',
      context: context,
    ) ?? false;
  }

  // ========== البحث والفلترة المتقدمة ==========

  /// البحث في المعاملات مع تحسين الأداء
  List<TransactionModel> searchTransactions(String query) {
    if (query.trim().isEmpty) return _transactions;
    
    final cacheKey = 'search_${query.toLowerCase()}_${_selectedMonth.year}_${_selectedMonth.month}';
    
    if (_enableCaching) {
      final cached = _cache.get<List<TransactionModel>>(cacheKey);
      if (cached != null) return cached;
    }
    
    final lowercaseQuery = query.toLowerCase();
    final results = _transactions.where((transaction) {
      return transaction.description.toLowerCase().contains(lowercaseQuery) ||
             transaction.category.toLowerCase().contains(lowercaseQuery) ||
             transaction.city.toLowerCase().contains(lowercaseQuery) ||
             transaction.notes?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
    
    if (_enableCaching && results.length < 100) {
      _cache.set(cacheKey, results, ttl: const Duration(minutes: 2));
    }
    
    return results;
  }

  /// فلترة المعاملات المتقدمة
  List<TransactionModel> filterTransactions({
    String? type,
    String? category,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    bool? isRecurring,
  }) {
    final filterKey = _generateFilterKey(
      type: type,
      category: category,
      city: city,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      isRecurring: isRecurring,
    );
    
    if (_enableCaching) {
      final cached = _cache.getCachedTransactions(filterKey);
      if (cached != null) return cached;
    }
    
    final filtered = _transactions.where((transaction) {
      if (type != null && transaction.type != type) return false;
      if (category != null && transaction.category != category) return false;
      if (city != null && transaction.city != city) return false;
      if (startDate != null && transaction.date.isBefore(startDate)) return false;
      if (endDate != null && transaction.date.isAfter(endDate)) return false;
      if (minAmount != null && transaction.amount < minAmount) return false;
      if (maxAmount != null && transaction.amount > maxAmount) return false;
      if (isRecurring != null && transaction.isRecurring != isRecurring) return false;
      return true;
    }).toList();
    
    if (_enableCaching && filtered.length < 200) {
      _cache.cacheTransactions(filterKey, filtered);
    }
    
    return filtered;
  }

  String _generateFilterKey({
    String? type,
    String? category,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    bool? isRecurring,
  }) {
    final parts = <String>[
      'filter',
      type ?? 'all',
      category ?? 'all',
      city ?? 'all',
      startDate?.toIso8601String() ?? 'none',
      endDate?.toIso8601String() ?? 'none',
      minAmount?.toString() ?? 'none',
      maxAmount?.toString() ?? 'none',
      isRecurring?.toString() ?? 'none',
    ];
    return parts.join('_');
  }

  /// تحميل المدن مع التخزين المؤقت
  Future<void> _loadCitiesWithCache() async {
    if (_enableCaching) {
      final cached = _cache.get<List<CityModel>>('cities');
      if (cached != null) {
        _cities = cached;
        return;
      }
    }
    
    final cities = await _errorHandler.handleDatabaseOperation(
      () => _db.getAllCities(),
      errorMessage: 'خطأ في تحميل المدن',
    );
    
    if (cities != null) {
      _cities = cities;
      if (_enableCaching) {
        _cache.set('cities', cities, ttl: const Duration(hours: 24));
      }
    }
  }

  /// تصفية الخطأ
  void clearError() {
    _clearError();
  }

  /// تحسين الأداء حسب الشاشة
  Future<void> optimizeForScreen(String screenName) async {
    await _memoryManager.optimizeForScreen(screenName);
    
    switch (screenName.toLowerCase()) {
      case 'reports':
        _enableCaching = true;
        _batchSize = 100;
        break;
      case 'history':
        _enableCaching = true;
        _batchSize = 50;
        break;
      case 'home':
        _enableCaching = true;
        _batchSize = 20;
        break;
    }
  }

  /// تنظيف الذاكرة والكاش
  void performCleanup() {
    _cache.cleanupExpired();
    _errorHandler.clearErrorLog();
  }

  @override
  void dispose() {
    _memoryManager.dispose();
    performCleanup();
    super.dispose();
  }
}