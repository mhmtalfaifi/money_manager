import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  
  String _userName = '';  // تغيير القيمة الافتراضية إلى فارغة
  bool _isLoading = false;
  String? _welcomeMessage;

  // Getters
  String get userName => _userName;
  bool get isLoading => _isLoading;
  String? get welcomeMessage => _welcomeMessage;

  /// تحميل بيانات المستخدم
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedName = await _userService.getUserName();
      _userName = loadedName;  // استخدام الاسم المحفوظ بدلاً من القيمة الافتراضية
      _welcomeMessage = await _userService.getWelcomeMessage();
    } catch (e) {
      // في حالة الخطأ فقط، استخدم القيمة الافتراضية
      _userName = await _userService.getUserName();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث اسم المستخدم
  Future<bool> updateUserName(String newName) async {
    if (!_userService.isValidName(newName)) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _userService.updateUserName(newName);
      
      if (success) {
        _userName = newName;
        _userService.updateCachedName(newName);
        _welcomeMessage = await _userService.getWelcomeMessage();
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// الحصول على اسم المستخدم بشكل متزامن
  String getUserNameSync() {
    return _userService.getUserNameSync();
  }

  /// تحديث رسالة الترحيب
  Future<void> refreshWelcomeMessage() async {
    try {
      _welcomeMessage = await _userService.getWelcomeMessage();
      notifyListeners();
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  /// إعادة تعيين بيانات المستخدم
  Future<bool> resetUserData() async {
    try {
      final success = await _userService.resetUserData();
      
      if (success) {
        _userName = '';
        _welcomeMessage = null;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من صحة الاسم
  bool isValidName(String name) {
    return _userService.isValidName(name);
  }

  /// الحصول على إحصائيات المستخدم
  Future<Map<String, dynamic>> getUserStats() async {
    return await _userService.getUserStats();
  }
}