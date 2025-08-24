import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // مفاتيح التخزين
  static const String _userNameKey = 'user_name';
  static const String _firstTimeUserKey = 'first_time_user';
  
  // إزالة القيمة الافتراضية
  String? _cachedUserName;

  /// التحقق من كون المستخدم جديد
  Future<bool> isFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_firstTimeUserKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// حفظ اسم المستخدم
  Future<bool> saveUserName(String name) async {
    try {
      if (name.trim().isEmpty) return false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name.trim());
      await prefs.setBool(_firstTimeUserKey, false);
      _cachedUserName = name.trim();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على اسم المستخدم
  Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_userNameKey);
      if (name != null && name.isNotEmpty) {
        _cachedUserName = name;
        return name;
      }
      return ''; // إرجاع قيمة فارغة بدلاً من قيمة افتراضية
    } catch (e) {
      return '';
    }
  }

  /// تحديث اسم المستخدم
  Future<bool> updateUserName(String newName) async {
    try {
      if (newName.trim().isEmpty) return false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, newName.trim());
      _cachedUserName = newName.trim();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// إعادة تعيين بيانات المستخدم
  Future<bool> resetUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userNameKey);
      await prefs.setBool(_firstTimeUserKey, true);
      _cachedUserName = null;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على اسم المستخدم بشكل متزامن
  String getUserNameSync() {
    return _cachedUserName ?? '';
  }

  /// تحديث الذاكرة المؤقتة
  void updateCachedName(String name) {
    _cachedUserName = name.trim();
  }

  /// التحقق من صحة الاسم
  bool isValidName(String name) {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty && 
           trimmedName.length >= 2 && 
           trimmedName.length <= 30;
  }

  /// الحصول على رسالة ترحيبية مخصصة
  Future<String> getWelcomeMessage() async {
    final name = await getUserName();
    if (name.isEmpty) return 'مرحباً';
    
    final hour = DateTime.now().hour;
    
    String greeting;
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء الخير';
    }
    
    return '$greeting، $name';
  }

  /// إحصائيات المستخدم
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'name': await getUserName(),
        'isFirstTime': await isFirstTimeUser(),
        'registrationDate': prefs.getString('registration_date') ?? DateTime.now().toIso8601String(),
        'lastLoginDate': prefs.getString('last_login_date') ?? DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'name': '',
        'isFirstTime': true,
        'registrationDate': DateTime.now().toIso8601String(),
        'lastLoginDate': DateTime.now().toIso8601String(),
      };
    }
  }

  /// تحديث آخر موعد دخول
  Future<void> updateLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login_date', DateTime.now().toIso8601String());
      
      if (!prefs.containsKey('registration_date')) {
        await prefs.setString('registration_date', DateTime.now().toIso8601String());
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  /// تحميل وتخزين اسم المستخدم في الذاكرة المؤقتة
  Future<void> loadUserName() async {
    _cachedUserName = await getUserName();
  }
}
