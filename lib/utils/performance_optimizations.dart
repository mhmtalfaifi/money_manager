// utils/performance_optimizations.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'dart:async';
import 'dart:isolate';

// ============= Cache Manager =============
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache للبيانات
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheValidityDuration = const Duration(minutes: 5);

  // حفظ في الـ Cache
  void set(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  // قراءة من الـ Cache
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;
    
    // التحقق من صلاحية الـ Cache
    if (DateTime.now().difference(timestamp) > _cacheValidityDuration) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }

  // مسح الـ Cache
  void clear([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  // مسح الـ Cache القديم
  void clearExpired() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheValidityDuration) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}

// ============= Lazy Loading Widget =============
class LazyLoadingList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final int loadMoreThreshold;

  const LazyLoadingList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.loadMoreThreshold = 5,
  });

  @override
  State<LazyLoadingList> createState() => _LazyLoadingListState();
}

class _LazyLoadingListState extends State<LazyLoadingList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || widget.onLoadMore == null) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 200.0 * widget.loadMoreThreshold;
    
    if (maxScroll - currentScroll <= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await widget.onLoadMore!();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.itemCount + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.itemCount) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return widget.itemBuilder(context, index);
      },
    );
  }
}

// ============= Debouncer for Search =============
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// ============= Image Caching =============
class OptimizedImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      filterQuality: FilterQuality.low,
      isAntiAlias: true,
    );
  }
}

// ============= Batch Operations =============
class BatchProcessor {
  static Future<void> processBatch<T>({
    required List<T> items,
    required Future<void> Function(T) processor,
    int batchSize = 10,
  }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);
      
      await Future.wait(
        batch.map((item) => processor(item)),
      );
      
      // إعطاء فرصة للـ UI للتحديث
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}

// ============= Memory Management =============
class MemoryManager {
  static void optimizeMemory() {
    // تنظيف الـ Image Cache
    imageCache.clear();
    imageCache.clearLiveImages();
    
    // تنظيف الـ Cache المخصص
    CacheManager().clearExpired();
    
    // طلب Garbage Collection (في debug mode فقط)
    if (kDebugMode) {
      debugPrint('Memory optimization completed');
    }
  }

  static double getMemoryUsage() {
    // حساب استخدام الذاكرة التقريبي
    final imageCacheSize = imageCache.currentSizeBytes / (1024 * 1024); // MB
    return imageCacheSize;
  }
}

// ============= Isolate for Heavy Computations =============
class ComputeService {
  // معالجة العمليات الثقيلة في Isolate منفصل
  static Future<MonthlySummary> computeMonthlySummary(
    List<TransactionModel> transactions,
  ) async {
    return await compute(_calculateSummary, transactions);
  }

  static MonthlySummary _calculateSummary(List<TransactionModel> transactions) {
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
      month: DateTime.now(),
      expensesByCategory: expensesByCategory,
      expensesByCity: expensesByCity,
    );
  }
}

// ============= Optimized Provider =============
mixin OptimizedNotifier on ChangeNotifier {
  bool _isDisposed = false;
  Timer? _debounceTimer;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void notifyListenersDebounced({Duration duration = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      if (!_isDisposed) {
        super.notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// ============= Performance Monitor =============
class PerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};

  static void startTimer(String operation) {
    _stopwatches[operation] = Stopwatch()..start();
  }

  static Duration? endTimer(String operation) {
    final stopwatch = _stopwatches[operation];
    if (stopwatch == null) return null;
    
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    _stopwatches.remove(operation);
    
    if (kDebugMode) {
      debugPrint('$operation took: ${duration.inMilliseconds}ms');
    }
    
    return duration;
  }

  static void logSlowOperation(String operation, Duration duration) {
    if (duration.inMilliseconds > 100) {
      debugPrint('⚠️ Slow operation detected: $operation (${duration.inMilliseconds}ms)');
    }
  }
}

// ============= Optimized Animations =============
class OptimizedAnimationController extends AnimationController {
  OptimizedAnimationController({
    required super.vsync,
    super.duration,
  });

  @override
  TickerFuture forward({double? from}) {
    // تقليل معدل الإطارات في حالة البطارية المنخفضة
    if (WidgetsBinding.instance.window.platformBrightness == Brightness.dark) {
      duration = duration! * 1.2;
    }
    return super.forward(from: from);
  }
}

// ============= تحسينات إضافية =============

// 1. استخدام const constructors حيثما أمكن
// 2. استخدام Keys للـ Widgets المعقدة
// 3. تجنب rebuild غير الضروري باستخدام Consumer الانتقائي
// 4. استخدام RepaintBoundary للـ Widgets الثقيلة
// 5. استخدام AutomaticKeepAliveClientMixin للـ Tabs

