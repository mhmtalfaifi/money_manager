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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
            builder: (context) => const AppWrapper(),
          );
        },
        
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const AppWrapper(),
          );
        },
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFC5D300), // أخضر فاتح
        brightness: Brightness.light,
        primary: const Color(0xFFC5D300), // أخضر فاتح
        onPrimary: Colors.white,
        secondary: const Color(0xFF473D33), // بني داكن
        onSecondary: Colors.white,
        background: const Color(0xFFF5F2E9), // خلفية بيج فاتح
      ),
      useMaterial3: true,
      fontFamily: 'Tajawal',
      
      // تخصيص الألوان
      primaryColor: const Color(0xFFC5D300), // أخضر فاتح
      scaffoldBackgroundColor: const Color(0xFFF5F2E9), // خلفية بيج فاتح
      
      // تخصيص AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFF5F2E9), // خلفية بيج فاتح
        foregroundColor: Color(0xFF473D33), // بني داكن
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF473D33), // بني داكن
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
          backgroundColor: const Color(0xFFC5D300), // أخضر فاتح
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      
      // تخصيص حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC5D300), width: 2), // أخضر فاتح
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      // تخصيص النصوص
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF473D33)), // بني داكن
        bodyMedium: TextStyle(color: Color(0xFF473D33)), // بني داكن
        titleLarge: TextStyle(color: Color(0xFF473D33)), // بني داكن
        titleMedium: TextStyle(color: Color(0xFF473D33)), // بني داكن
        titleSmall: TextStyle(color: Color(0xFF473D33)), // بني داكن
      ),
      
      // تخصيص الأيقونات
      iconTheme: const IconThemeData(
        color: Color(0xFF473D33), // بني داكن
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFC5D300), // أخضر فاتح
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Tajawal',
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