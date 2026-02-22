import 'dart:ui';

extension HexColor on Color {
  /// örnek kullanım: `Color.hex("#FF5733")` veya `Color.hex("FF5733")`
  static Color hex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    hexString = hexString.replaceFirst('#', '');
    buffer.write(hexString);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}