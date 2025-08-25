// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'utils/app_colors.dart';
import 'helpers/database_helper.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_provider.dart';
import 'services/user_service.dart';

void main() async {
  // التأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();

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
    // في حالة فشل التهيئة، عرض شاشة خطأ
    runApp(ErrorApp(error: e.toString()));
  }
}

/// تهيئة جميع الخدمات
Future<void> _initializeServices() async {
  try {
    // تهيئة خدمة المستخدم
    await UserService().loadUserName();
    await UserService().updateLastLogin();
    
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
      systemNavigationBarColor: Color(0xFFF5F2E9), // خلفية بيج فاتح
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  if (kDebugMode) {
    debugPrint('✅ System settings configured');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstTimeUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    try {
      final userService = UserService();
      final isFirstTime = await userService.isFirstTimeUser();
      final userName = await userService.getUserName();
      
      // إذا كان مستخدم جديد أو لا يوجد اسم محفوظ
      final shouldShowWelcome = isFirstTime || userName.isEmpty;
      
      if (mounted) {
        setState(() {
          _showWelcome = shouldShowWelcome;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showWelcome = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // تحديث البيانات عند العودة للتطبيق
      _refreshData();
    }
  }

  void _refreshData() {
    // يمكن إضافة منطق تحديث البيانات هنا
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'إدارة المصروفات',
        theme: _buildTheme(),
        home: const Scaffold(
          backgroundColor: Color(0xFFF5F2E9),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFC5D300),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'إدارة المصروفات',
        theme: _buildTheme(),
        home: _showWelcome ? const WelcomeScreen() : const HomeScreen(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [
          Locale('ar', 'SA'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      fontFamily: 'Amiri',
      scaffoldBackgroundColor: const Color(0xFFF5F2E9),
      // إجبار استخدام الأرقام الإنجليزية
      textTheme: const TextTheme().apply(
        fontFamily: 'Amiri',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF473D33)),
        titleTextStyle: TextStyle(
          color: Color(0xFF473D33),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }
  }
/// غلاف التطبيق الذي يقرر أي شاشة يعرض
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstTimeUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// التحقق من كون المستخدم جديد
  Future<void> _checkFirstTimeUser() async {
    try {
      final isFirstTime = await UserService().isFirstTimeUser();
      
      // تحميل بيانات المستخدم في الProvider
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        await userProvider.loadUserData();
      }
      
      if (mounted) {
        setState(() {
          _showWelcome = isFirstTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      // في حالة الخطأ، اعرض شاشة الترحيب للأمان
      if (mounted) {
        setState(() {
          _showWelcome = true;
          _isLoading = false;
        });
      }
    }
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

  void _performBackgroundCleanup() {
    if (kDebugMode) {
      debugPrint('🧹 Background cleanup performed');
    }
  }

  void _refreshDataOnResume() {
    // إعادة تحميل البيانات عند العودة للتطبيق
    if (!_showWelcome && mounted) {
      final transactionProvider = context.read<TransactionProvider>();
      final userProvider = context.read<UserProvider>();
      
      transactionProvider.loadInitialData();
      userProvider.loadUserData();
    }
    
    if (kDebugMode) {
      debugPrint('🔄 Data refreshed on app resume');
    }
  }

  void _performFinalCleanup() {
    if (kDebugMode) {
      debugPrint('👋 Final cleanup performed');
    }
  }

  @override
  Widget build(BuildContext context) {
    // شاشة التحميل
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2E9), // خلفية بيج فاتح
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار التطبيق
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFC5D300), // أخضر فاتح
                      Color(0xFFA5B800), // درجة أخضر أغمق قليلاً
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC5D300).withOpacity(0.3), // أخضر فاتح مع شفافية
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // مؤشر التحميل
              const CircularProgressIndicator(
                color: Color(0xFFC5D300), // أخضر فاتح
                strokeWidth: 3,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'جاري التحميل...',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF473D33).withOpacity(0.7), // بني داكن مع شفافية
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // عرض الشاشة المناسبة
    return _showWelcome ? const WelcomeScreen() : const HomeScreen();
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
        backgroundColor: const Color(0xFFF5F2E9), // خلفية بيج فاتح
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: const Color(0xFF473D33), // بني داكن
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'حدث خطأ في تهيئة التطبيق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF473D33), // بني داكن
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'يرجى إعادة تشغيل التطبيق',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF473D33).withOpacity(0.7), // بني داكن مع شفافية
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: () {
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5D300), // أخضر فاتح
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
                
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'تفاصيل الخطأ:\n$error',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF473D33), // بني داكن
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}