// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'utils/app_colors.dart';
import 'helpers/database_helper.dart';
import 'providers/transaction_provider.dart';
import 'services/error_handler_service.dart';
import 'services/cache_service.dart';
import 'services/memory_manager_service.dart';

void main() async {
  // التأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة خدمة معالجة الأخطاء أولاً
  final errorHandler = ErrorHandlerService();
  errorHandler.initialize();

  try {
    // تهيئة الخدمات الأساسية
    await _initializeServices();
    
    // تهيئة قاعدة البيانات حسب المنصة
    await _initializeDatabase();

    // إعدادات النظام
    await _setupSystemSettings();
    
    // تشغيل التطبيق
    runApp(const MyApp());
    
  } catch (e) {
    errorHandler.logSimpleError('فشل في تهيئة التطبيق: $e');
    
    // في حالة فشل التهيئة، عرض شاشة خطأ
    runApp(ErrorApp(error: e.toString()));
  }
}

/// تهيئة جميع الخدمات
Future<void> _initializeServices() async {
  try {
    // تهيئة التخزين المؤقت
    await CacheService().initialize();
    
    // تهيئة مدير الذاكرة
    MemoryManagerService().initialize(
      onMemoryWarning: () {
        if (kDebugMode) {
          debugPrint('⚠️ Memory warning received');
        }
      },
      onMemoryCritical: () {
        if (kDebugMode) {
          debugPrint('🚨 Critical memory situation');
        }
      },
    );
    
    if (kDebugMode) {
      debugPrint('✅ All services initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Service initialization failed: $e');
    }
    rethrow;
  }
}

/// تهيئة قاعدة البيانات
Future<void> _initializeDatabase() async {
  if (!kIsWeb) {
    // للموبايل (iOS & Android) - استخدم sqflite العادي
    if (defaultTargetPlatform == TargetPlatform.iOS || 
        defaultTargetPlatform == TargetPlatform.android) {
      await DatabaseHelper.instance.database;
      
      if (kDebugMode) {
        debugPrint('✅ Database initialized for mobile platform');
      }
    }
  } else {
    if (kDebugMode) {
      debugPrint('ℹ️ Web platform detected - database features limited');
    }
  }
}

/// إعداد إعدادات النظام
Future<void> _setupSystemSettings() async {
  // إجبار الوضع العمودي فقط (للموبايل)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // إعدادات شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  if (kDebugMode) {
    debugPrint('✅ System settings configured');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'مدير الأموال',
        debugShowCheckedModeBanner: false,
        
        // دعم اللغة العربية
        locale: const Locale('ar', 'SA'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'SA'),
        ],
        
        // معالج الأخطاء على مستوى التطبيق
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0), // منع تكبير النص من إعدادات النظام
            ),
            child: child!,
          );
        },
        
        // التصميم
        theme: _buildAppTheme(),
        
        // الوضع الليلي (معطل حالياً)
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.light,
        
        // الصفحة الرئيسية
        home: const AppWrapper(),
        
        // معالجة الأخطاء في التنقل
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          );
        },
        
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Tajawal',
      
      // تخصيص الألوان
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // تخصيص AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      
      // تخصيص البطاقات
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // تخصيص الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      
      // تخصيص الـ FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppColors.addButton,
      ),
      
      // تخصيص SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF121212),
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      cardTheme: CardThemeData( 
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

/// غلاف للتطبيق مع معالجة الحالات الاستثنائية
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // تحسين الأداء عند بدء التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _optimizeAppStart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // تنظيف عند الانتقال للخلفية
        _performBackgroundCleanup();
        break;
      case AppLifecycleState.resumed:
        // تحديث البيانات عند العودة
        _refreshDataOnResume();
        break;
      case AppLifecycleState.detached:
        // تنظيف نهائي
        _performFinalCleanup();
        break;
      default:
        break;
    }
  }

  void _optimizeAppStart() {
    // تنظيف الكاش القديم
    CacheService().cleanupExpired();
    
    // تحسين الذاكرة للشاشة الرئيسية
    MemoryManagerService().optimizeForScreen('home');
  }

  void _performBackgroundCleanup() {
    // تنظيف خفيف عند الانتقال للخلفية
    CacheService().cleanupExpired();
    
    if (kDebugMode) {
      debugPrint('🧹 Background cleanup performed');
    }
  }

  void _refreshDataOnResume() {
    // إعادة تحميل البيانات عند العودة للتطبيق
    final provider = context.read<TransactionProvider>();
    provider.loadInitialData();
    
    if (kDebugMode) {
      debugPrint('🔄 Data refreshed on app resume');
    }
  }

  void _performFinalCleanup() {
    // تنظيف نهائي عند إغلاق التطبيق
    MemoryManagerService().dispose();
    
    if (kDebugMode) {
      debugPrint('👋 Final cleanup performed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

/// شاشة خطأ في حالة فشل تهيئة التطبيق
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خطأ في التطبيق',
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[700],
                ),
                const SizedBox(height: 24),
                Text(
                  'فشل في تشغيل التطبيق',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'نعتذر، حدث خطأ أثناء تشغيل التطبيق',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // إعادة تشغيل التطبيق
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}