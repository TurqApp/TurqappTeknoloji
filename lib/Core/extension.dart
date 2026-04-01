import 'dart:ui';

extension HexColor on Color {
  static Color hex(String hexString) {
    final cleaned = hexString.replaceFirst('#', '');
    final value =
        '${cleaned.length == 6 || cleaned.length == 7 ? 'ff' : ''}$cleaned';
    return Color(int.parse(value, radix: 16));
  }
}
