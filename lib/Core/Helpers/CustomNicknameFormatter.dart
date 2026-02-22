
// Türkçe karakterleri engelleyen ve küçük harfe dönüştüren bir formatter
import 'package:flutter/services.dart';

class CustomNicknameFormatter extends TextInputFormatter {
  // Sadece a-z, 0-9 ve _ izin ver, tüm harfleri küçük yap
  final RegExp _allowedChars = RegExp(r'[a-z0-9_]');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Girilen değeri küçük harfe çevir
    String lower = newValue.text.toLowerCase();

    // Sadece izin verilen karakterleri bırak
    String filtered = lower.split('').where((c) => _allowedChars.hasMatch(c)).join();

    // İmleç konumunu koru
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}