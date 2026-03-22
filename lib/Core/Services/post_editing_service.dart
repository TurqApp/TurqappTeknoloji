import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'post_editing_service_history_part.dart';
part 'post_editing_service_suggestions_part.dart';

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

class PostEditingService extends GetxController {
  static PostEditingService? maybeFind() {
    final isRegistered = Get.isRegistered<PostEditingService>();
    if (!isRegistered) return null;
    return Get.find<PostEditingService>();
  }

  static PostEditingService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PostEditingService());
  }

  final RxList<EditAction> _undoStack = <EditAction>[].obs;
  final RxList<EditAction> _redoStack = <EditAction>[].obs;
  final Rx<TextFormatting> _currentFormatting = TextFormatting().obs;
  final RxList<SmartSuggestion> _suggestions = <SmartSuggestion>[].obs;
  final RxBool _smartSuggestionsEnabled = true.obs;
  final RxString _currentText = ''.obs;

  static const int _maxUndoActions = 50;
  static const List<String> _commonHashtags = [
    '#fotoğraf',
    '#video',
    '#müzik',
    '#sanat',
    '#seyahat',
    '#yemek',
    '#spor',
    '#teknoloji',
    '#kitap',
    '#film',
    '#doğa',
    '#arkadaş'
  ];

  // Getters
  List<EditAction> get undoStack => _undoStack;
  List<EditAction> get redoStack => _redoStack;
  TextFormatting get currentFormatting => _currentFormatting.value;
  List<SmartSuggestion> get suggestions => _suggestions;
  bool get smartSuggestionsEnabled => _smartSuggestionsEnabled.value;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _startSuggestionGeneration();
  }
}
