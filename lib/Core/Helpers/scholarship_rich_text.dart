import 'package:flutter/material.dart';

class ScholarshipRichText {
  static const List<String> _highlightPhrases = [
    'basvuru nasil yapilir',
    'basvuru nasil yapilacak',
    'gerekli belgeler',
    'burs basvuru sartlari',
    'basvuruda oncelikli olanlar',
    'burs verilmeyecek olanlar',
    'basvuru tarihleri',
    'basvuru icin gerekli belgeler',
  ];
  static final RegExp _listPrefixPattern = RegExp(
    r'^(\s*(?:\d+\s*\)|[a-zA-Z]\s*[\)\.-]))(\s*)',
  );

  static TextSpan build(
    String text, {
    required TextStyle baseStyle,
  }) {
    final boldStyle = baseStyle.copyWith(
      fontFamily: 'MontserratBold',
      fontWeight: FontWeight.w700,
    );

    final lines = text.split('\n');
    final children = <InlineSpan>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      children.addAll(
        _buildLineSpans(
          line,
          trimmed,
          baseStyle: baseStyle,
          boldStyle: boldStyle,
        ),
      );
      if (i != lines.length - 1) {
        children.add(TextSpan(text: '\n', style: baseStyle));
      }
    }

    return TextSpan(children: children, style: baseStyle);
  }

  static List<InlineSpan> _buildLineSpans(
    String line,
    String trimmed, {
    required TextStyle baseStyle,
    required TextStyle boldStyle,
  }) {
    if (_shouldHighlightHeading(trimmed)) {
      return [TextSpan(text: line, style: boldStyle)];
    }

    final match = _listPrefixPattern.firstMatch(line);
    if (match == null) {
      return [TextSpan(text: line, style: baseStyle)];
    }

    final prefix = match.group(1) ?? '';
    final spacing = match.group(2) ?? '';
    final remainingText = line.substring(match.end);

    return [
      TextSpan(text: prefix, style: boldStyle),
      if (spacing.isNotEmpty) TextSpan(text: spacing, style: baseStyle),
      if (remainingText.isNotEmpty)
        TextSpan(text: remainingText, style: baseStyle),
    ];
  }

  static bool _shouldHighlightHeading(String line) {
    if (line.isEmpty) return false;

    final normalized = _normalize(line);
    for (final phrase in _highlightPhrases) {
      if (normalized.contains(phrase)) {
        return true;
      }
    }

    return false;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
  }
}
