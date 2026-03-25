part of 'post_editing_service.dart';

class EditAction {
  final String id;
  final String type;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final DateTime timestamp;

  EditAction({
    required this.id,
    required this.type,
    required this.beforeState,
    required this.afterState,
    required this.timestamp,
  });
}

class TextFormatting {
  final bool bold;
  final bool italic;
  final bool underline;
  final Color? textColor;
  final double fontSize;
  final String fontFamily;

  TextFormatting({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.textColor,
    this.fontSize = 14.0,
    this.fontFamily = 'MontserratRegular',
  });

  TextFormatting copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    Color? textColor,
    double? fontSize,
    String? fontFamily,
  }) =>
      TextFormatting(
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        textColor: textColor ?? this.textColor,
        fontSize: fontSize ?? this.fontSize,
        fontFamily: fontFamily ?? this.fontFamily,
      );

  TextStyle toTextStyle() => TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
        color: textColor,
        fontSize: fontSize,
        fontFamily: fontFamily,
      );

  Map<String, dynamic> toJson() => {
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'textColor': textColor?.toARGB32(),
        'fontSize': fontSize,
        'fontFamily': fontFamily,
      };

  factory TextFormatting.fromJson(Map<String, dynamic> json) => TextFormatting(
        bold: json['bold'] ?? false,
        italic: json['italic'] ?? false,
        underline: json['underline'] ?? false,
        textColor: json['textColor'] != null ? Color(json['textColor']) : null,
        fontSize: json['fontSize']?.toDouble() ?? 14.0,
        fontFamily: json['fontFamily'] ?? 'MontserratRegular',
      );
}

class SmartSuggestion {
  final String type;
  final String text;
  final String suggestion;
  final Map<String, dynamic> metadata;

  SmartSuggestion({
    required this.type,
    required this.text,
    required this.suggestion,
    this.metadata = const {},
  });
}
