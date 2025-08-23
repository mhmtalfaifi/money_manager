import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../helpers/database_helper.dart';

class BackupService {
  static const _channel = MethodChannel('com.moneymanager/backup');
  
  // نسخ احتياطي محلي
  static Future<bool> createLocalBackup() async {
    try {
      final db = DatabaseHelper.instance;
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.db';
      
      // نسخ قاعدة البيانات
      final dbPath = await getDatabasesPath();
      final originalPath = join(dbPath, 'money_manager.db');
      final originalFile = File(originalPath);
      
      await originalFile.copy(backupPath);
      
      return true;
    } catch (e) {
      print('Backup error: $e');
      return false;
    }
  }
  
  // استعادة من نسخة احتياطية
  static Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final dbPath = await getDatabasesPath();
      final originalPath = join(dbPath, 'money_manager.db');
      
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) return false;
      
      // إغلاق قاعدة البيانات الحالية
      await DatabaseHelper.instance.close();
      
      // استبدال قاعدة البيانات
      await backupFile.copy(originalPath);
      
      // إعادة فتح قاعدة البيانات
      await DatabaseHelper.instance.database;
      
      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
  
  // نسخ احتياطي في السحابة (Google Drive / iCloud)
  static Future<bool> createCloudBackup() async {
    try {
      // إنشاء نسخة احتياطية محلية أولاً
      await createLocalBackup();
      
      // رفع إلى السحابة حسب النظام
      if (Platform.isAndroid) {
        return await _channel.invokeMethod('uploadToGoogleDrive');
      } else if (Platform.isIOS) {
        return await _channel.invokeMethod('uploadToiCloud');
      }
      
      return false;
    } catch (e) {
      print('Cloud backup error: $e');
      return false;
    }
  }
  
  // استعادة من السحابة
  static Future<bool> restoreFromCloud() async {
    try {
      String? backupPath;
      
      if (Platform.isAndroid) {
        backupPath = await _channel.invokeMethod('downloadFromGoogleDrive');
      } else if (Platform.isIOS) {
        backupPath = await _channel.invokeMethod('downloadFromiCloud');
      }
      
      if (backupPath != null) {
        return await restoreFromBackup(backupPath);
      }
      
      return false;
    } catch (e) {
      print('Cloud restore error: $e');
      return false;
    }
  }
}
