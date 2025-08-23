// helpers/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول العمليات المالية
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        city TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    // جدول الفئات
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        isDefault INTEGER NOT NULL DEFAULT 0,
        UNIQUE(name, type)
      )
    ''');

    // جدول المدن
    await db.execute('''
      CREATE TABLE cities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        isDefault INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // جدول الميزانيات
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT
      )
    ''');

    // إضافة البيانات الافتراضية
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    // إضافة الفئات الافتراضية
    for (String category in AppConstants.defaultIncomeCategories) {
      await db.insert('categories', {
        'name': category,
        'type': 'income',
        'isDefault': 1,
      });
    }

    for (String category in AppConstants.defaultExpenseCategories) {
      await db.insert('categories', {
        'name': category,
        'type': 'expense',
        'isDefault': 1,
      });
    }

    for (String category in AppConstants.defaultCommitmentCategories) {
      await db.insert('categories', {
        'name': category,
        'type': 'commitment',
        'isDefault': 1,
      });
    }

    // إضافة المدن الافتراضية
    for (String city in AppConstants.defaultCities) {
      await db.insert('cities', {
        'name': city,
        'isDefault': 1,
      });
    }
  }

  // ============ عمليات CRUD للمعاملات ============

  // إضافة معاملة جديدة
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  // الحصول على جميع المعاملات
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // الحصول على معاملات شهر معين
  Future<List<TransactionModel>> getTransactionsByMonth(DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final result = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC, createdAt DESC',
    );
    
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // الحصول على معاملات حسب النوع
  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // الحصول على معاملات حسب المدينة
  Future<List<TransactionModel>> getTransactionsByCity(String city) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'city = ?',
      whereArgs: [city],
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // تحديث معاملة
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // حذف معاملة
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ عمليات الفئات ============

  // الحصول على الفئات حسب النوع
  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  // إضافة فئة جديدة
  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  // ============ عمليات المدن ============

  // الحصول على جميع المدن
  Future<List<CityModel>> getAllCities() async {
    final db = await database;
    final result = await db.query('cities', orderBy: 'name ASC');
    return result.map((map) => CityModel.fromMap(map)).toList();
  }

  // إضافة مدينة جديدة
  Future<int> insertCity(CityModel city) async {
    final db = await database;
    return await db.insert('cities', city.toMap());
  }

  // ============ عمليات الميزانية ============

  // الحصول على الميزانيات
  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await database;
    final result = await db.query('budgets', orderBy: 'category ASC');
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  // إضافة ميزانية
  Future<int> insertBudget(BudgetModel budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  // تحديث ميزانية
  Future<int> updateBudget(BudgetModel budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // ============ دوال الإحصائيات ============

  // حساب مجموع حسب النوع والشهر
  Future<double> getTotalByTypeAndMonth(String type, DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ? AND date BETWEEN ? AND ?
    ''', [type, startDate.toIso8601String(), endDate.toIso8601String()]);
    
    final total = result.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  // الحصول على ملخص شهري
  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    final transactions = await getTransactionsByMonth(month);
    
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalCommitments = 0;
    Map<String, double> expensesByCategory = {};
    Map<String, double> expensesByCity = {};

    for (var transaction in transactions) {
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

    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalCommitments: totalCommitments,
      month: month,
      expensesByCategory: expensesByCategory,
      expensesByCity: expensesByCity,
    );
  }

  // معالجة الالتزامات الشهرية
  Future<void> processMonthlyCommitments(DateTime month) async {
    final db = await database;
    
    // البحث عن الالتزامات المتكررة من الشهر السابق
    final lastMonth = DateTime(month.year, month.month - 1);
    final result = await db.query(
      'transactions',
      where: 'type = ? AND isRecurring = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        'commitment',
        1,
        DateTime(lastMonth.year, lastMonth.month, 1).toIso8601String(),
        DateTime(lastMonth.year, lastMonth.month + 1, 0).toIso8601String(),
      ],
    );
    
    // إضافة الالتزامات للشهر الحالي
    for (var map in result) {
      final commitment = TransactionModel.fromMap(map);
      
      // التحقق من عدم وجود نفس الالتزام في الشهر الحالي
      final existing = await db.query(
        'transactions',
        where: 'type = ? AND description = ? AND date BETWEEN ? AND ?',
        whereArgs: [
          'commitment',
          commitment.description,
          DateTime(month.year, month.month, 1).toIso8601String(),
          DateTime(month.year, month.month + 1, 0).toIso8601String(),
        ],
      );
      
      if (existing.isEmpty) {
        // إنشاء التزام جديد للشهر الحالي
        final newCommitment = TransactionModel(
          type: 'commitment',
          description: commitment.description,
          amount: commitment.amount,
          category: commitment.category,
          city: commitment.city,
          date: DateTime(month.year, month.month, commitment.date.day),
          isRecurring: true,
          notes: commitment.notes,
        );
        
        await insertTransaction(newCommitment);
      }
    }
  }

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}