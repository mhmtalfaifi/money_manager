// models/transaction_model.dart

/// نموذج المعاملة المالية
class TransactionModel {
  final int? id;
  final String type; // income, expense, commitment
  final String description;
  final double amount;
  final String category;
  final String city;
  final DateTime date;
  final DateTime createdAt;
  final bool isRecurring;
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

  /// تحويل من Map إلى Model
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id']?.toInt(),
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      city: map['city'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isRecurring: (map['isRecurring'] ?? 0) == 1,
      notes: map['notes'],
    );
  }

  /// تحويل من Model إلى Map
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

  /// إنشاء نسخة محدثة من المعاملة
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

  @override
  String toString() {
    return 'TransactionModel{id: $id, type: $type, description: $description, amount: $amount, category: $category, city: $city, date: $date, isRecurring: $isRecurring}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.type == type &&
        other.description == description &&
        other.amount == amount &&
        other.category == category &&
        other.city == city &&
        other.date == date &&
        other.isRecurring == isRecurring &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        category.hashCode ^
        city.hashCode ^
        date.hashCode ^
        isRecurring.hashCode ^
        notes.hashCode;
  }
}

/// نموذج الفئة
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

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      icon: map['icon'],
      isDefault: (map['isDefault'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'CategoryModel{id: $id, name: $name, type: $type, isDefault: $isDefault}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.icon == icon &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        type.hashCode ^
        icon.hashCode ^
        isDefault.hashCode;
  }
}

/// نموذج المدينة
class CityModel {
  final int? id;
  final String name;
  final bool isDefault;

  CityModel({
    this.id,
    required this.name,
    this.isDefault = false,
  });

  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      isDefault: (map['isDefault'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  CityModel copyWith({
    int? id,
    String? name,
    bool? isDefault,
  }) {
    return CityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'CityModel{id: $id, name: $name, isDefault: $isDefault}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityModel &&
        other.id == id &&
        other.name == name &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ isDefault.hashCode;
  }
}

/// نموذج الميزانية
class BudgetModel {
  final int? id;
  final String category;
  final double amount;
  final String period; // monthly, quarterly, yearly
  final DateTime startDate;
  final DateTime? endDate;

  BudgetModel({
    this.id,
    required this.category,
    required this.amount,
    this.period = 'monthly', // قيمة افتراضية
    required this.startDate,
    this.endDate,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id']?.toInt(),
      category: map['category'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      period: map['period'] ?? 'monthly',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
    );
  }

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

  BudgetModel copyWith({
    int? id,
    String? category,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  String toString() {
    return 'BudgetModel{id: $id, category: $category, amount: $amount, period: $period, startDate: $startDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel &&
        other.id == id &&
        other.category == category &&
        other.amount == amount &&
        other.period == period &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        category.hashCode ^
        amount.hashCode ^
        period.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }
}

/// نموذج الملخص الشهري
class MonthlySummary {
  final double totalIncome;
  final double totalExpenses;
  final double totalCommitments;
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
  });

  double get netIncome => totalIncome - totalExpenses - totalCommitments;
  double get totalOutgoing => totalExpenses + totalCommitments;
  double get savingsRate => totalIncome > 0 ? (netIncome / totalIncome) * 100 : 0;
  double get balance => netIncome; // الرصيد المتبقي
  double get expenseRate => totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0; // نسبة المصروفات

  factory MonthlySummary.fromMap(Map<String, dynamic> map) {
    return MonthlySummary(
      totalIncome: map['totalIncome']?.toDouble() ?? 0.0,
      totalExpenses: map['totalExpenses']?.toDouble() ?? 0.0,
      totalCommitments: map['totalCommitments']?.toDouble() ?? 0.0,
      month: DateTime.parse(map['month'] ?? DateTime.now().toIso8601String()),
      expensesByCategory: Map<String, double>.from(map['expensesByCategory'] ?? {}),
      expensesByCity: Map<String, double>.from(map['expensesByCity'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalCommitments': totalCommitments,
      'month': month.toIso8601String(),
      'expensesByCategory': expensesByCategory,
      'expensesByCity': expensesByCity,
    };
  }

  MonthlySummary copyWith({
    double? totalIncome,
    double? totalExpenses,
    double? totalCommitments,
    DateTime? month,
    Map<String, double>? expensesByCategory,
    Map<String, double>? expensesByCity,
  }) {
    return MonthlySummary(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalCommitments: totalCommitments ?? this.totalCommitments,
      month: month ?? this.month,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      expensesByCity: expensesByCity ?? this.expensesByCity,
    );
  }

  @override
  String toString() {
    return 'MonthlySummary{totalIncome: $totalIncome, totalExpenses: $totalExpenses, totalCommitments: $totalCommitments, month: $month, netIncome: $netIncome}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlySummary &&
        other.totalIncome == totalIncome &&
        other.totalExpenses == totalExpenses &&
        other.totalCommitments == totalCommitments &&
        other.month == month;
  }

  @override
  int get hashCode {
    return totalIncome.hashCode ^
        totalExpenses.hashCode ^
        totalCommitments.hashCode ^
        month.hashCode;
  }
}