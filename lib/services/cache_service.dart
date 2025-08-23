// services/cache_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';

/// خدمة التخزين المؤقت المتقدمة
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // التخزين المؤقت في الذاكرة
  final Map<String, CacheItem> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // إعدادات التخزين المؤقت
  static const Duration _defaultTTL = Duration(minutes: 5);
  static const Duration _summaryTTL = Duration(minutes: 1);
  static const Duration _categoriesTTL = Duration(minutes: 30);
  static const int _maxMemoryItems = 50;

  File? _cacheFile;

  /// تهيئة خدمة التخزين المؤقت
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _cacheFile = File('${directory.path}/app_cache.json');
      
      // تحميل الكاش المحفوظ
      await _loadPersistentCache();
      
      // بدء تنظيف دوري
      _startPeriodicCleanup();
      
      if (kDebugMode) {
        debugPrint('✅ Cache Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache Service initialization failed: $e');
      }
    }
  }

  /// حفظ في التخزين المؤقت
  void set<T>(String key, T data, {Duration? ttl}) {
    final cacheItem = CacheItem<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _getDefaultTTL(key),
    );
    
    _memoryCache[key] = cacheItem;
    _cacheTimestamps[key] = DateTime.now();
    
    // تنظيف الذاكرة إذا تجاوزت الحد
    _cleanupMemoryIfNeeded();
    
    // حفظ مستمر للبيانات المهمة
    if (_shouldPersist(key)) {
      _saveToPersistentCache(key, cacheItem);
    }
  }

  /// استرجاع من التخزين المؤقت
  T? get<T>(String key) {
    final cacheItem = _memoryCache[key];
    if (cacheItem == null) return null;
    
    // التحقق من انتهاء الصلاحية
    if (_isExpired(cacheItem)) {
      remove(key);
      return null;
    }
    
    // تحديث وقت الوصول
    _cacheTimestamps[key] = DateTime.now();
    
    return cacheItem.data as T?;
  }

  /// التحقق من وجود البيانات في الكاش
  bool has(String key) {
    final cacheItem = _memoryCache[key];
    if (cacheItem == null) return false;
    
    if (_isExpired(cacheItem)) {
      remove(key);
      return false;
    }
    
    return true;
  }

  /// حذف من التخزين المؤقت
  void remove(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// مسح كامل للتخزين المؤقت
  void clear() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _clearPersistentCache();
  }

  /// مسح البيانات المنتهية الصلاحية
  void cleanupExpired() {
    final expiredKeys = <String>[];
    
    _memoryCache.forEach((key, item) {
      if (_isExpired(item)) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      remove(key);
    }
    
    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleaned up ${expiredKeys.length} expired cache items');
    }
  }

  /// الحصول على أو تعيين البيانات
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() dataProvider, {
    Duration? ttl,
  }) async {
    // محاولة الحصول من الكاش
    final cachedData = get<T>(key);
    if (cachedData != null) {
      return cachedData;
    }
    
    // إذا لم توجد، احصل على البيانات الجديدة
    final newData = await dataProvider();
    set(key, newData, ttl: ttl);
    
    return newData;
  }

  // ========== دوال خاصة بالتطبيق ==========

  /// تخزين مؤقت للملخص الشهري
  void cacheMonthlySummary(DateTime month, MonthlySummary summary) {
    final key = 'monthly_summary_${month.year}_${month.month}';
    set(key, summary, ttl: _summaryTTL);
  }

  /// استرجاع الملخص الشهري من الكاش
  MonthlySummary? getCachedMonthlySummary(DateTime month) {
    final key = 'monthly_summary_${month.year}_${month.month}';
    return get<MonthlySummary>(key);
  }

  /// تخزين مؤقت للمعاملات
  void cacheTransactions(String filterKey, List<TransactionModel> transactions) {
    final key = 'transactions_$filterKey';
    set(key, transactions, ttl: _summaryTTL);
  }

  /// استرجاع المعاملات من الكاش
  List<TransactionModel>? getCachedTransactions(String filterKey) {
    final key = 'transactions_$filterKey';
    return get<List<TransactionModel>>(key);
  }

  /// تخزين مؤقت للفئات
  void cacheCategories(String type, List<CategoryModel> categories) {
    final key = 'categories_$type';
    set(key, categories, ttl: _categoriesTTL);
  }

  /// استرجاع الفئات من الكاش
  List<CategoryModel>? getCachedCategories(String type) {
    final key = 'categories_$type';
    return get<List<CategoryModel>>(key);
  }

  /// تخزين مؤقت للإحصائيات
  void cacheStatistics(String key, Map<String, dynamic> stats) {
    set('stats_$key', stats, ttl: const Duration(minutes: 2));
  }

  /// استرجاع الإحصائيات من الكاش
  Map<String, dynamic>? getCachedStatistics(String key) {
    return get<Map<String, dynamic>>('stats_$key');
  }

  /// إلغاء الصلاحية عند تحديث البيانات
  void invalidateRelatedCache(String dataType) {
    final keysToRemove = <String>[];
    
    switch (dataType) {
      case 'transactions':
        // إلغاء كاش المعاملات والملخصات
        _memoryCache.keys.where((key) => 
          key.startsWith('transactions_') ||
          key.startsWith('monthly_summary_') ||
          key.startsWith('stats_')
        ).forEach((key) => keysToRemove.add(key));
        break;
        
      case 'categories':
        // إلغاء كاش الفئات
        _memoryCache.keys.where((key) => 
          key.startsWith('categories_')
        ).forEach((key) => keysToRemove.add(key));
        break;
        
      case 'budgets':
        // إلغاء كاش الميزانيات والإحصائيات
        _memoryCache.keys.where((key) => 
          key.startsWith('budgets_') ||
          key.startsWith('stats_')
        ).forEach((key) => keysToRemove.add(key));
        break;
    }
    
    for (final key in keysToRemove) {
      remove(key);
    }
    
    if (kDebugMode && keysToRemove.isNotEmpty) {
      debugPrint('🗑️ Invalidated ${keysToRemove.length} cache items for $dataType');
    }
  }

  // ========== دوال داخلية ==========

  bool _isExpired(CacheItem item) {
    return DateTime.now().difference(item.timestamp) > item.ttl;
  }

  Duration _getDefaultTTL(String key) {
    if (key.startsWith('monthly_summary_')) return _summaryTTL;
    if (key.startsWith('categories_')) return _categoriesTTL;
    if (key.startsWith('stats_')) return const Duration(minutes: 2);
    return _defaultTTL;
  }

  bool _shouldPersist(String key) {
    // فقط الفئات والمدن تحتاج حفظ مستمر
    return key.startsWith('categories_') || key.startsWith('cities_');
  }

  void _cleanupMemoryIfNeeded() {
    if (_memoryCache.length <= _maxMemoryItems) return;
    
    // ترتيب حسب آخر وصول وحذف الأقدم
    final sortedKeys = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final keysToRemove = sortedKeys
        .take(_memoryCache.length - _maxMemoryItems)
        .map((e) => e.key)
        .toList();
    
    for (final key in keysToRemove) {
      remove(key);
    }
    
    if (kDebugMode) {
      debugPrint('🧹 Memory cleanup: removed ${keysToRemove.length} items');
    }
  }

  void _startPeriodicCleanup() {
    // تنظيف كل 5 دقائق
    Stream.periodic(const Duration(minutes: 5)).listen((_) {
      cleanupExpired();
    });
  }

  // ========== التخزين المستمر ==========

  Future<void> _saveToPersistentCache(String key, CacheItem item) async {
    try {
      if (_cacheFile == null) return;
      
      Map<String, dynamic> persistentData = {};
      
      // قراءة البيانات الموجودة
      if (await _cacheFile!.exists()) {
        final content = await _cacheFile!.readAsString();
        if (content.isNotEmpty) {
          persistentData = jsonDecode(content);
        }
      }
      
      // إضافة البيانات الجديدة
      persistentData[key] = {
        'data': _serializeData(item.data),
        'timestamp': item.timestamp.toIso8601String(),
        'ttl_minutes': item.ttl.inMinutes,
      };
      
      // كتابة البيانات
      await _cacheFile!.writeAsString(jsonEncode(persistentData));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save persistent cache: $e');
      }
    }
  }

  Future<void> _loadPersistentCache() async {
    try {
      if (_cacheFile == null || !await _cacheFile!.exists()) return;
      
      final content = await _cacheFile!.readAsString();
      if (content.isEmpty) return;
      
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      data.forEach((key, value) {
        try {
          final timestamp = DateTime.parse(value['timestamp']);
          final ttlMinutes = value['ttl_minutes'] as int;
          final ttl = Duration(minutes: ttlMinutes);
          
          // التحقق من انتهاء الصلاحية
          if (DateTime.now().difference(timestamp) < ttl) {
            final deserializedData = _deserializeData(key, value['data']);
            if (deserializedData != null) {
              _memoryCache[key] = CacheItem(
                data: deserializedData,
                timestamp: timestamp,
                ttl: ttl,
              );
              _cacheTimestamps[key] = timestamp;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Failed to load cache item $key: $e');
          }
        }
      });
      
      if (kDebugMode) {
        debugPrint('📥 Loaded ${_memoryCache.length} items from persistent cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load persistent cache: $e');
      }
    }
  }

  Future<void> _clearPersistentCache() async {
    try {
      if (_cacheFile != null && await _cacheFile!.exists()) {
        await _cacheFile!.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear persistent cache: $e');
      }
    }
  }

  dynamic _serializeData(dynamic data) {
    if (data is List<CategoryModel>) {
      return {'type': 'CategoryList', 'data': data.map((e) => e.toMap()).toList()};
    } else if (data is List<CityModel>) {
      return {'type': 'CityList', 'data': data.map((e) => e.toMap()).toList()};
    }
    return data;
  }

  dynamic _deserializeData(String key, dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('type')) {
      switch (data['type']) {
        case 'CategoryList':
          return (data['data'] as List)
              .map((e) => CategoryModel.fromMap(e))
              .toList();
        case 'CityList':
          return (data['data'] as List)
              .map((e) => CityModel.fromMap(e))
              .toList();
      }
    }
    return data;
  }

  // ========== معلومات الكاش ==========

  /// الحصول على معلومات الكاش
  CacheInfo getCacheInfo() {
    final totalItems = _memoryCache.length;
    final expiredCount = _memoryCache.values
        .where((item) => _isExpired(item))
        .length;
    
    final sizeEstimate = _estimateMemoryUsage();
    
    return CacheInfo(
      totalItems: totalItems,
      expiredItems: expiredCount,
      estimatedSizeKB: sizeEstimate,
    );
  }

  int _estimateMemoryUsage() {
    // تقدير تقريبي لاستخدام الذاكرة بالكيلوبايت
    int estimate = 0;
    _memoryCache.forEach((key, item) {
      estimate += key.length;
      estimate += _estimateDataSize(item.data);
    });
    return estimate ~/ 1024; // تحويل إلى KB
  }

  int _estimateDataSize(dynamic data) {
    if (data is String) return data.length;
    if (data is List) return data.length * 50; // تقدير متوسط
    if (data is Map) return data.length * 100; // تقدير متوسط
    return 50; // قيمة افتراضية
  }
}

/// عنصر في التخزين المؤقت
class CacheItem<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheItem({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
}

/// معلومات التخزين المؤقت
class CacheInfo {
  final int totalItems;
  final int expiredItems;
  final int estimatedSizeKB;

  CacheInfo({
    required this.totalItems,
    required this.expiredItems,
    required this.estimatedSizeKB,
  });

  int get validItems => totalItems - expiredItems;
  
  @override
  String toString() {
    return 'CacheInfo{total: $totalItems, valid: $validItems, expired: $expiredItems, size: ${estimatedSizeKB}KB}';
  }
}