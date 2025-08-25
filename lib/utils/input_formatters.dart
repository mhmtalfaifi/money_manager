// utils/input_formatters.dart

import 'package:flutter/services.dart';

class EnglishNumbersOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // خريطة تحويل الأرقام الهندية إلى الأرقام الإنجليزية
    const arabicToEnglish = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    String newText = newValue.text;
    
    // تحويل الأرقام الهندية إلى أرقام إنجليزية
    arabicToEnglish.forEach((arabic, english) {
      newText = newText.replaceAll(arabic, english);
    });

    // السماح بالأرقام الإنجليزية والنقطة العشرية فقط
    newText = newText.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // التأكد من وجود نقطة عشرية واحدة فقط
    List<String> parts = newText.split('.');
    if (parts.length > 2) {
      newText = parts[0] + '.' + parts.sublist(1).join('');
    }
    
    // الحد الأقصى للأرقام العشرية (خانتين)
    if (parts.length == 2 && parts[1].length > 2) {
      newText = parts[0] + '.' + parts[1].substring(0, 2);
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class WholeNumbersOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // خريطة تحويل الأرقام الهندية إلى الأرقام الإنجليزية
    const arabicToEnglish = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    String newText = newValue.text;
    
    // تحويل الأرقام الهندية إلى أرقام إنجليزية
    arabicToEnglish.forEach((arabic, english) {
      newText = newText.replaceAll(arabic, english);
    });

    // السماح بالأرقام الإنجليزية فقط
    newText = newText.replaceAll(RegExp(r'[^0-9]'), '');

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}