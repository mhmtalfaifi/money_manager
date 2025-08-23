// services/memory_manager_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cache_service.dart';

/// خدمة إدارة الذاكرة المتقدمة
class MemoryManagerService {
  static final MemoryManagerService _instance = MemoryManagerService._internal();
  factory MemoryManagerService() => _instance;
  MemoryManagerService._internal();

  Timer? _memoryMonitorTimer;
  final List<MemorySnapshot> _memoryHistory = [];
  final int _maxHistorySize = 50;
  
  // عتبات التحذير
  static const int _warningThresholdMB = 100;
  static const int _criticalThresholdMB = 150;
  
  bool _isMonitoring = false;
  VoidCallback? _onMemoryWarning;
  VoidCallback? _onMemoryCritical;

  /// تهيئة مدير الذاكرة
  void initialize({
    VoidCallback? onMemoryWarning,
    VoidCallback? onMemoryCritical,
  }) {
    _onMemoryWarning = onMemoryWarning;
    _onMemoryCritical = onMemoryCritical;
    
    // بدء المراقبة في وضع التطوير أو عند الحاجة
    if (kDebugMode) {
      startMonitoring();
    }
  }

  /// بدء مراقبة الذاكرة
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _memoryMonitorTimer = Timer.periodic(interval, (_) => _checkMemoryUsage());
    
    if (kDebugMode) {
      debugPrint('🔍 Memory monitoring started');
    }
  }

  /// إيقاف مراقبة الذاكرة
  void stopMonitoring() {
    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    
    if (kDebugMode) {
      debugPrint('⏹️ Memory monitoring stopped');
    }
  }

  /// فحص استخدام الذاكرة
  Future<MemoryInfo> checkMemoryUsage() async {
    final info = await _getMemoryInfo();
    _addToHistory(MemorySnapshot(
      timestamp: DateTime.now(),
      usedMemoryMB: info.usedMemoryMB,
      availableMemoryMB: info.availableMemoryMB,
      imageCache: info.imageCacheSize,
    ));
    
    return info;
  }

  Future<void> _checkMemoryUsage() async {
    try {
      final info = await checkMemoryUsage();
      
      // تحقق من العتبات
      if (info.usedMemoryMB > _criticalThresholdMB) {
        await _handleCriticalMemory();
        _onMemoryCritical?.call();
      } else if (info.usedMemoryMB > _warningThresholdMB) {
        await _handleMemoryWarning();
        _onMemoryWarning?.call();
      }
      
      if (kDebugMode) {
        debugPrint('💾 Memory: ${info.usedMemoryMB}MB used, ${info.availableMemoryMB}MB available');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Memory check failed: $e');
      }
    }
  }

  /// الحصول على معلومات الذاكرة
  Future<MemoryInfo> _getMemoryInfo() async {
    // حساب ذاكرة التطبيق التقريبية
    final imageCacheSize = _getImageCacheSize();
    final appMemoryMB = (imageCacheSize / (1024 * 1024)) + _getEstimatedAppMemory();
    
    // محاولة الحصول على ذاكرة النظام (Android فقط)
    int? systemMemory;
    if (Platform.isAndroid) {
      systemMemory = await _getSystemMemory();
    }
    
    return MemoryInfo(
      usedMemoryMB: appMemoryMB.round(),
      availableMemoryMB: systemMemory ?? 1024, // قيمة افتراضية
      imageCacheSize: imageCacheSize,
      timestamp: DateTime.now(),
    );
  }

  int _getImageCacheSize() {
    try {
      return imageCache.currentSizeBytes;
    } catch (e) {
      return 0;
    }
  }

  double _getEstimatedAppMemory() {
    // تقدير تقريبي لذاكرة التطبيق
    double estimate = 20.0; // ذاكرة أساسية
    
    // إضافة ذاكرة الكاش
    final cacheInfo = CacheService().getCacheInfo();
    estimate += cacheInfo.estimatedSizeKB / 1024.0;
    
    return estimate;
  }

  Future<int?> _getSystemMemory() async {
    try {
      // استخدام MethodChannel للحصول على معلومات الذاكرة من Android
      const MethodChannel channel = MethodChannel('com.moneymanager/memory');
      final int? availableMemory = await channel.invokeMethod('getAvailableMemory');
      return availableMemory;
    } catch (e) {
      return null;
    }
  }

  /// التعامل مع تحذير الذاكرة
  Future<void> _handleMemoryWarning() async {
    if (kDebugMode) {
      debugPrint('⚠️ Memory warning triggered');
    }
    
    // تنظيف خفيف
    await _lightMemoryCleanup();
  }

  /// التعامل مع حالة الذاكرة الحرجة
  Future<void> _handleCriticalMemory() async {
    if (kDebugMode) {
      debugPrint('🚨 Critical memory situation');
    }
    
    // تنظيف شامل
    await _aggressiveMemoryCleanup();
  }

  /// تنظيف خفيف للذاكرة
  Future<void> _lightMemoryCleanup() async {
    // تنظيف الكاش المنتهي الصلاحية
    CacheService().cleanupExpired();
    
    // تقليل حجم ذاكرة الصور
    imageCache.clearLiveImages();
    
    if (kDebugMode) {
      debugPrint('🧹 Light memory cleanup completed');
    }
  }

  /// تنظيف شامل للذاكرة
  Future<void> _aggressiveMemoryCleanup() async {
    // مسح كامل لذاكرة الصور
    imageCache.clear();
    imageCache.clearLiveImages();
    
    // مسح الكاش غير الحيوي
    CacheService().clear();
    
    if (kDebugMode) {
      debugPrint('🗑️ Aggressive memory cleanup completed');
    }
  }

  /// تنظيف يدوي للذاكرة
  Future<MemoryCleanupResult> performManualCleanup({bool aggressive = false}) async {
    final beforeInfo = await checkMemoryUsage();
    
    if (aggressive) {
      await _aggressiveMemoryCleanup();
    } else {
      await _lightMemoryCleanup();
    }
    
    // انتظار قصير لتطبيق التنظيف
    await Future.delayed(const Duration(milliseconds: 500));
    
    final afterInfo = await checkMemoryUsage();
    final freedMB = beforeInfo.usedMemoryMB - afterInfo.usedMemoryMB;
    
    return MemoryCleanupResult(
      beforeMemoryMB: beforeInfo.usedMemoryMB,
      afterMemoryMB: afterInfo.usedMemoryMB,
      freedMemoryMB: freedMB,
      aggressive: aggressive,
    );
  }

  /// تحسين الذاكرة لشاشة معينة
  Future<void> optimizeForScreen(String screenName) async {
    switch (screenName.toLowerCase()) {
      case 'reports':
        // تنظيف البيانات القديمة قبل تحميل التقارير
        CacheService().invalidateRelatedCache('stats');
        break;
      case 'history':
        // تحسين للقوائم الطويلة
        await _lightMemoryCleanup();
        break;
      case 'home':
        // تحسين عام
        CacheService().cleanupExpired();
        break;
    }
  }

  void _addToHistory(MemorySnapshot snapshot) {
    _memoryHistory.add(snapshot);
    
    // الحفاظ على حد أقصى للسجل
    if (_memoryHistory.length > _maxHistorySize) {
      _memoryHistory.removeAt(0);
    }
  }

  /// الحصول على سجل الذاكرة
  List<MemorySnapshot> get memoryHistory => List.unmodifiable(_memoryHistory);

  /// الحصول على إحصائيات الذاكرة
  MemoryStatistics getMemoryStatistics() {
    if (_memoryHistory.isEmpty) {
      return MemoryStatistics.empty();
    }
    
    final usages = _memoryHistory.map((s) => s.usedMemoryMB).toList();
    final average = usages.reduce((a, b) => a + b) / usages.length;
    final peak = usages.reduce((a, b) => a > b ? a : b);
    final current = _memoryHistory.last.usedMemoryMB;
    
    return MemoryStatistics(
      currentUsageMB: current,
      averageUsageMB: average.round(),
      peakUsageMB: peak,
      samplesCount: _memoryHistory.length,
    );
  }

  /// التحقق من صحة الذاكرة
  MemoryHealthStatus getMemoryHealth() {
    final stats = getMemoryStatistics();
    
    if (stats.currentUsageMB > _criticalThresholdMB) {
      return MemoryHealthStatus.critical;
    } else if (stats.currentUsageMB > _warningThresholdMB) {
      return MemoryHealthStatus.warning;
    } else if (stats.peakUsageMB > _warningThresholdMB) {
      return MemoryHealthStatus.caution;
    } else {
      return MemoryHealthStatus.good;
    }
  }

  /// تنظيف عند إغلاق التطبيق
  void dispose() {
    stopMonitoring();
    _memoryHistory.clear();
  }
}

/// معلومات الذاكرة
class MemoryInfo {
  final int usedMemoryMB;
  final int availableMemoryMB;
  final int imageCacheSize;
  final DateTime timestamp;

  MemoryInfo({
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.imageCacheSize,
    required this.timestamp,
  });

  double get usagePercentage => 
      (usedMemoryMB / (usedMemoryMB + availableMemoryMB)) * 100;

  @override
  String toString() {
    return 'MemoryInfo{used: ${usedMemoryMB}MB, available: ${availableMemoryMB}MB, usage: ${usagePercentage.toStringAsFixed(1)}%}';
  }
}

/// لقطة للذاكرة
class MemorySnapshot {
  final DateTime timestamp;
  final int usedMemoryMB;
  final int availableMemoryMB;
  final int imageCache;

  MemorySnapshot({
    required this.timestamp,
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.imageCache,
  });
}

/// إحصائيات الذاكرة
class MemoryStatistics {
  final int currentUsageMB;
  final int averageUsageMB;
  final int peakUsageMB;
  final int samplesCount;

  MemoryStatistics({
    required this.currentUsageMB,
    required this.averageUsageMB,
    required this.peakUsageMB,
    required this.samplesCount,
  });

  factory MemoryStatistics.empty() {
    return MemoryStatistics(
      currentUsageMB: 0,
      averageUsageMB: 0,
      peakUsageMB: 0,
      samplesCount: 0,
    );
  }

  @override
  String toString() {
    return 'MemoryStats{current: ${currentUsageMB}MB, avg: ${averageUsageMB}MB, peak: ${peakUsageMB}MB}';
  }
}

/// نتيجة تنظيف الذاكرة
class MemoryCleanupResult {
  final int beforeMemoryMB;
  final int afterMemoryMB;
  final int freedMemoryMB;
  final bool aggressive;

  MemoryCleanupResult({
    required this.beforeMemoryMB,
    required this.afterMemoryMB,
    required this.freedMemoryMB,
    required this.aggressive,
  });

  bool get wasEffective => freedMemoryMB > 0;
  double get effectivenessPercentage => 
      beforeMemoryMB > 0 ? (freedMemoryMB / beforeMemoryMB) * 100 : 0;

  @override
  String toString() {
    return 'MemoryCleanup{freed: ${freedMemoryMB}MB, effectiveness: ${effectivenessPercentage.toStringAsFixed(1)}%}';
  }
}

/// حالة صحة الذاكرة
enum MemoryHealthStatus {
  good('جيدة', Colors.green),
  caution('انتباه', Colors.orange),
  warning('تحذير', Colors.amber),
  critical('حرجة', Colors.red);

  const MemoryHealthStatus(this.label, this.color);
  final String label;
  final Color color;
}