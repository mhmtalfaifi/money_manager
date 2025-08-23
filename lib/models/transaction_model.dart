// models/transaction_model.dart

class TransactionModel {
  final int? id;
  final String type; // income, expense, commitment
  final String description;
  final double amount;
  final String category;
  final String city;
  final DateTime date;
  final DateTime createdAt;
  final bool isRecurring; // للالتزامات الشهرية
  final String? notes;

  TransactionModel({
    this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.category,
    required this.city,
    required this.date,
    DateTime? createdAt,
    this.isRecurring = false,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  // تحويل من وإلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'category': category,
      'city': city,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      description: map['description'],
      amount: map['amount'],
      category: map['category'],
      city: map['city'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      isRecurring: map['isRecurring'] == 1,
      notes: map['notes'],
    );
  }

  // نسخة محدثة من العملية
  TransactionModel copyWith({
    int? id,
    String? type,
    String? description,
    double? amount,
    String? category,
    String? city,
    DateTime? date,
    DateTime? createdAt,
    bool? isRecurring,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      city: city ?? this.city,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      notes: notes ?? this.notes,
    );
  }

  // حساب إذا كانت العملية في شهر معين
  bool isInMonth(DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  // حساب إذا كانت العملية في سنة معينة
  bool isInYear(int year) {
    return date.year == year;
  }

  // الحصول على اسم النوع بالعربي
  String get typeArabic {
    switch (type) {
      case 'income':
        return 'دخل';
      case 'expense':
        return 'مصروف';
      case 'commitment':
        return 'التزام';
      default:
        return 'غير محدد';
    }
  }
}

// نموذج الفئة
class CategoryModel {
  final int? id;
  final String name;
  final String type; // income, expense, commitment
  final String? icon;
  final bool isDefault;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      icon: map['icon'],
      isDefault: map['isDefault'] == 1,
    );
  }
}

// نموذج المدينة
class CityModel {
  final int? id;
  final String name;
  final bool isDefault;

  CityModel({
    this.id,
    required this.name,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: map['id'],
      name: map['name'],
      isDefault: map['isDefault'] == 1,
    );
  }
}

// نموذج الميزانية
class BudgetModel {
  final int? id;
  final String category;
  final double amount;
  final String period; // monthly, yearly
  final DateTime startDate;
  final DateTime? endDate;

  BudgetModel({
    this.id,
    required this.category,
    required this.amount,
    this.period = 'monthly',
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      period: map['period'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
    );
  }
}

// نموذج الملخص الشهري
class MonthlySummary {
  final double totalIncome;
  final double totalExpenses;
  final double totalCommitments;
  final double balance;
  final DateTime month;
  final Map<String, double> expensesByCategory;
  final Map<String, double> expensesByCity;

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalCommitments,
    required this.month,
    this.expensesByCategory = const {},
    this.expensesByCity = const {},
  }) : balance = totalIncome - totalExpenses - totalCommitments;

  double get savingsRate {
    if (totalIncome == 0) return 0;
    return (balance / totalIncome) * 100;
  }

  double get expenseRate {
    if (totalIncome == 0) return 0;
    return ((totalExpenses + totalCommitments) / totalIncome) * 100;
  }
}