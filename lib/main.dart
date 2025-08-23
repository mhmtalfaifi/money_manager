import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_colors.dart';
import 'helpers/database_helper.dart';
import 'providers/transaction_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة قاعدة البيانات حسب المنصة
  if (!kIsWeb) {
    // للموبايل (iOS & Android) - استخدم sqflite العادي
    if (defaultTargetPlatform == TargetPlatform.iOS || 
        defaultTargetPlatform == TargetPlatform.android) {
      // تهيئة قاعدة البيانات للموبايل
      await DatabaseHelper.instance.database;
    } 
    // للديسكتوب (Windows, macOS, Linux)
    else {
      try {
        // استخدم sqflite_common_ffi للديسكتوب فقط
        final sqfliteFfiInit = await _initDesktopDatabase();
        if (sqfliteFfiInit != null) {
          await DatabaseHelper.instance.database;
        }
      } catch (e) {
        print("Desktop database initialization failed: $e");
      }
    }
  } else {
    // على Web: يمكن ترك قاعدة البيانات فارغة
    print("تشغيل على الويب: قاعدة البيانات غير متوفرة");
  }

  // إجبار الوضع العمودي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

// دالة منفصلة لتهيئة قاعدة البيانات للديسكتوب
Future<bool?> _initDesktopDatabase() async {
  try {
    // تحميل ديناميكي للمكتبة فقط عند الحاجة
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // هنا يمكن إضافة كود خاص بالديسكتوب إذا لزم
      return null; // نرجع null لأننا لن ندعم الديسكتوب حالياً
    }
    return null;
  } catch (e) {
    print("Desktop database error: $e");
    return null;
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
        
        // التصميم
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Cairo',
          
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
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          // تخصيص البطاقات
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          
          // تخصيص الأزرار
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // الوضع الليلي
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Cairo',
          scaffoldBackgroundColor: const Color(0xFF121212),
          
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF121212),
            titleTextStyle: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          cardTheme: CardThemeData( 
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        
        themeMode: ThemeMode.system, // تتبع إعدادات النظام
        
        home: const HomeScreen(),
      ),
    );
  }
}