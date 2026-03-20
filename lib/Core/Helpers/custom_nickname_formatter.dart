// Nickname için Türkçe karakterleri ASCII'ye çeviren ve güvenli karakter seti uygulayan formatter
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

class CustomNicknameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filtered = normalizeEditableNickname(newValue.text);

    // İmleç konumunu koru
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
