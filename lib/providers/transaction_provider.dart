// providers/transaction_provider.dart

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
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
  
  // البيانات
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<CityModel> _cities = [];
  List<BudgetModel> _budgets = [];
  
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

  // ========== التهيئة والتحميل ==========

  /// تحميل البيانات الأولية مع معالجة الأخطاء
  Future<void> loadInitialData() async {
    await _performOperation(
      operation: () async {
        await _memoryManager.optimizeForScreen('home');
        
        // معالجة الالتزامات الشهرية
        await _errorHandler.handleDatabaseOperation(
          () => _db.processMonthlyCommitments(_selectedMonth),
          errorMessage: 'خطأ في معالجة الالتزامات الشهرية',
        );

        // تحميل البيانات بشكل متوازي مع معالجة الأخطاء
        await Future.wait([
          _loadTransactionsWithCache(),
          _loadCategoriesWithCache(),
          _loadCitiesWithCache(),
          _loadBudgetsWithCache(),
        ]);
      },
      loadingMessage: 'جاري تحميل البيانات...',
    );
  }

  /// تحميل المعاملات مع التخزين المؤقت
  Future<void> _loadTransactionsWithCache() async {
    final cacheKey = 'month_${_selectedMonth.year}_${_selectedMonth.month}';
    
    if (_enableCaching) {
      final cachedTransactions = _cache.getCachedTransactions(cacheKey);
      final cachedSummary = _cache.getCachedMonthlySummary(_selectedMonth);
      
      if (cachedTransactions != null && cachedSummary != null) {
        _transactions = cachedTransactions;
        _monthlySummary = cachedSummary;
        return;
      }
    }
    
    // تحميل من قاعدة البيانات
    final transactions = await _errorHandler.handleDatabaseOperation(
      () => _db.getTransactionsByMonth(_selectedMonth),
      errorMessage: 'خطأ في تحميل المعاملات',
    );
    
    final summary = await _errorHandler.handleDatabaseOperation(
      () => _db.getMonthlySummary(_selectedMonth),
      errorMessage: 'خطأ في حساب الملخص الشهري',
    );
    
    if (transactions != null) {
      _transactions = transactions;
      if (_enableCaching) {
        _cache.cacheTransactions(cacheKey, transactions);
      }
    }
    
    if (summary != null) {
      _monthlySummary = summary;
      if (_enableCaching) {
        _cache.cacheMonthlySummary(_selectedMonth, summary);
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

  /// تحميل المدن مع التخزين المؤقت
  Future<void> _loadCitiesWithCache() async {
    if (_enableCaching) {
      final cached = _cache.getCachedCategories('cities');
      if (cached != null) {
        _cities = cached as List<CityModel>;
        return;
      }
    }
    
    final cities = await _errorHandler.handleDatabaseOperation(
      () => _db.getAllCities(),
      errorMessage: 'خطأ في تحميل المدن',
    );
    
    if (cities != null) {
      _cities = cities;
    }
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

  // ========== إدارة المعاملات ==========

  /// إضافة معاملة جديدة مع معالجة شاملة للأخطاء
  Future<bool> addTransaction(TransactionModel transaction, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        // التحقق من صحة البيانات
        _validateTransaction(transaction);
        
        // إدراج في قاعدة البيانات
        final id = await _db.insertTransaction(transaction);
        
        if (id > 0) {
          // تحديث الكاش
          _cache.invalidateRelatedCache('transactions');
          
          // إعادة تحميل البيانات
          await _loadTransactionsWithCache();
          
          // التحقق من تجاوز الميزانية
          if (transaction.type == 'expense') {
            await _checkBudgetAlert(transaction.category, context);
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

  /// تحديث معاملة مع معالجة الأخطاء
  Future<bool> updateTransaction(TransactionModel transaction, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        _validateTransaction(transaction);
        
        final rowsAffected = await _db.updateTransaction(transaction);
        
        if (rowsAffected > 0) {
          _cache.invalidateRelatedCache('transactions');
          await _loadTransactionsWithCache();
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري تحديث المعاملة...',
      successMessage: 'تم تحديث المعاملة بنجاح',
      context: context,
    ) ?? false;
  }

  /// حذف معاملة مع معالجة الأخطاء
  Future<bool> deleteTransaction(int id, {BuildContext? context}) async {
    return await _performOperation<bool>(
      operation: () async {
        final rowsAffected = await _db.deleteTransaction(id);
        
        if (rowsAffected > 0) {
          _cache.invalidateRelatedCache('transactions');
          await _loadTransactionsWithCache();
          return true;
        }
        return false;
      },
      loadingMessage: 'جاري حذف المعاملة...',
      successMessage: 'تم حذف المعاملة بنجاح',
      context: context,
    ) ?? false;
  }

  // ========== إدارة الفئات والمدن ==========

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

  // ========== إدارة الميزانيات ==========

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
    if (message != null && loading) {
      // يمكن عرض رسالة التحميل هنا
    }
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
        // يمكن إرسال إشعار هنا
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

  // ========== تغيير الشهر والفلترة ==========

  /// تغيير الشهر المحدد مع إعادة تحميل البيانات
  Future<void> changeMonth(DateTime month, {BuildContext? context}) async {
    if (_selectedMonth.year == month.year && _selectedMonth.month == month.month) {
      return; // نفس الشهر، لا حاجة للتحديث
    }
    
    await _performOperation(
      operation: () async {
        _selectedMonth = month;
        await _loadTransactionsWithCache();
      },
      loadingMessage: 'جاري تحميل بيانات ${DateFormat('MMMM yyyy', 'ar').format(month)}...',
      context: context,
    );
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

  // ========== الإحصائيات المتقدمة ==========

  /// الحصول على إحصائيات مخصصة مع تخزين مؤقت
  Map<String, dynamic> getAdvancedStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final statsKey = 'advanced_${startDate?.toIso8601String() ?? 'none'}_${endDate?.toIso8601String() ?? 'none'}';
    
    final cached = _cache.getCachedStatistics(statsKey);
    if (cached != null) return cached;
    
    final transactions = startDate != null || endDate != null
        ? filterTransactions(startDate: startDate, endDate: endDate)
        : _transactions;
    
    final stats = <String, dynamic>{
      'totalTransactions': transactions.length,
      'totalIncome': _calculateTotalByType(transactions, 'income'),
      'totalExpenses': _calculateTotalByType(transactions, 'expense'),
      'totalCommitments': _calculateTotalByType(transactions, 'commitment'),
      'averageTransaction': _calculateAverageTransaction(transactions),
      'largestTransaction': _findLargestTransaction(transactions),
      'smallestTransaction': _findSmallestTransaction(transactions),
      'mostActiveDay': _findMostActiveDay(transactions),
      'categoryBreakdown': _calculateCategoryBreakdown(transactions),
      'cityBreakdown': _calculateCityBreakdown(transactions),
      'monthlyTrends': _calculateMonthlyTrends(transactions),
    };
    
    _cache.cacheStatistics(statsKey, stats);
    return stats;
  }

  double _calculateTotalByType(List<TransactionModel> transactions, String type) {
    return transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateAverageTransaction(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 0.0;
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    return total / transactions.length;
  }

  TransactionModel? _findLargestTransaction(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return null;
    return transactions.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  TransactionModel? _findSmallestTransaction(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return null;
    return transactions.reduce((a, b) => a.amount < b.amount ? a : b);
  }

  String _findMostActiveDay(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 'لا توجد بيانات';
    
    final dayCount = <String, int>{};
    for (final transaction in transactions) {
      final dayName = DateFormat('EEEE', 'ar').format(transaction.date);
      dayCount[dayName] = (dayCount[dayName] ?? 0) + 1;
    }
    
    return dayCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Map<String, double> _calculateCategoryBreakdown(List<TransactionModel> transactions) {
    final breakdown = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type != 'income') {
        breakdown[transaction.category] = 
            (breakdown[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return breakdown;
  }

  Map<String, double> _calculateCityBreakdown(List<TransactionModel> transactions) {
    final breakdown = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type != 'income') {
        breakdown[transaction.city] = 
            (breakdown[transaction.city] ?? 0) + transaction.amount;
      }
    }
    return breakdown;
  }

  Map<String, double> _calculateMonthlyTrends(List<TransactionModel> transactions) {
    final trends = <String, double>{};
    for (final transaction in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(transaction.date);
      trends[monthKey] = (trends[monthKey] ?? 0) + transaction.amount;
    }
    return trends;
  }

  // ========== دوال مساعدة موجودة مع تحسينات ==========

  List<CategoryModel> getCategoriesByType(String type) {
    final cached = _cache.getCachedCategories(type);
    if (cached != null) return cached;
    
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
    
    return (spent / budget.amount).clamp(0.0, 2.0); // يسمح بتجاوز 200%
  }

  List<TransactionModel> getRecentTransactions({int limit = 5}) {
    final cacheKey = 'recent_$limit';
    final cached = _cache.get<List<TransactionModel>>(cacheKey);
    if (cached != null) return cached;
    
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final recent = sorted.take(limit).toList();
    _cache.set(cacheKey, recent, ttl: const Duration(minutes: 1));
    
    return recent;
  }

  // ========== إدارة الأداء والذاكرة ==========

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

  /// تصفية الخطأ
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _memoryManager.dispose();
    performCleanup();
    super.dispose();
  }
}