
// Nickname için Türkçe karakterleri ASCII'ye çeviren ve güvenli karakter seti uygulayan formatter
import 'package:flutter/services.dart';

class CustomNicknameFormatter extends TextInputFormatter {
  // Sadece a-z, 0-9, "_" ve "." izin ver
  final RegExp _allowedChars = RegExp(r'[a-z0-9._]');
  static const Map<String, String> _trMap = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
  };

  String _normalize(String input) {
    var lower = input.toLowerCase();
    for (final entry in _trMap.entries) {
      lower = lower.replaceAll(entry.key, entry.value);
    }
    return lower;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final normalized = _normalize(newValue.text);

    // Sadece izin verilen karakterleri bırak
    final filtered =
        normalized.split('').where((c) => _allowedChars.hasMatch(c)).join();

    // İmleç konumunu koru
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
