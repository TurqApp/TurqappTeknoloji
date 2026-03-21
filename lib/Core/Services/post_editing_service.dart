import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

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

  /// Record an edit action for undo/redo
  void recordAction({
    required String type,
    required Map<String, dynamic> beforeState,
    required Map<String, dynamic> afterState,
  }) {
    final action = EditAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      beforeState: beforeState,
      afterState: afterState,
      timestamp: DateTime.now(),
    );

    _undoStack.add(action);
    _redoStack.clear(); // Clear redo stack when new action is performed

    // Keep only recent actions
    if (_undoStack.length > _maxUndoActions) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo last action
  Map<String, dynamic>? undo() {
    if (_undoStack.isEmpty) return null;

    final lastAction = _undoStack.removeLast();
    _redoStack.add(lastAction);

    return lastAction.beforeState;
  }

  /// Redo last undone action
  Map<String, dynamic>? redo() {
    if (_redoStack.isEmpty) return null;

    final lastUndone = _redoStack.removeLast();
    _undoStack.add(lastUndone);

    return lastUndone.afterState;
  }

  /// Clear undo/redo history
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Update text formatting
  void updateFormatting(TextFormatting newFormatting) {
    final oldFormatting = _currentFormatting.value;

    recordAction(
      type: 'formatting',
      beforeState: {'formatting': oldFormatting.toJson()},
      afterState: {'formatting': newFormatting.toJson()},
    );

    _currentFormatting.value = newFormatting;
  }

  /// Toggle bold formatting
  void toggleBold() {
    updateFormatting(_currentFormatting.value.copyWith(
      bold: !_currentFormatting.value.bold,
    ));
  }

  /// Toggle italic formatting
  void toggleItalic() {
    updateFormatting(_currentFormatting.value.copyWith(
      italic: !_currentFormatting.value.italic,
    ));
  }

  /// Toggle underline formatting
  void toggleUnderline() {
    updateFormatting(_currentFormatting.value.copyWith(
      underline: !_currentFormatting.value.underline,
    ));
  }

  /// Change font size
  void changeFontSize(double newSize) {
    updateFormatting(_currentFormatting.value.copyWith(
      fontSize: newSize.clamp(10.0, 24.0),
    ));
  }

  /// Change text color
  void changeTextColor(Color newColor) {
    updateFormatting(_currentFormatting.value.copyWith(
      textColor: newColor,
    ));
  }

  /// Start smart suggestion generation
  void _startSuggestionGeneration() {
    // Listen to text changes
    ever(_currentText, (String text) {
      if (_smartSuggestionsEnabled.value && text.isNotEmpty) {
        _generateSuggestions(text);
      }
    });
  }

  /// Update current text for suggestion generation
  void updateCurrentText(String text) {
    _currentText.value = text;
  }

  /// Generate smart suggestions based on text content
  void _generateSuggestions(String text) {
    _suggestions.clear();

    // Hashtag suggestions
    final hashtagSuggestions = _generateHashtagSuggestions(text);
    _suggestions.addAll(hashtagSuggestions);

    // Mention suggestions (if text contains @)
    if (text.contains('@')) {
      final mentionSuggestions = _generateMentionSuggestions(text);
      _suggestions.addAll(mentionSuggestions);
    }

    // Grammar and spell check suggestions
    final grammarSuggestions = _generateGrammarSuggestions(text);
    _suggestions.addAll(grammarSuggestions);

    // Content enhancement suggestions
    final contentSuggestions = _generateContentSuggestions(text);
    _suggestions.addAll(contentSuggestions);
  }

  /// Generate hashtag suggestions
  List<SmartSuggestion> _generateHashtagSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
    final normalizedText = normalizeSearchText(text);
    final words = normalizedText.split(' ');

    // Check for relevant hashtags based on keywords
    for (final hashtag in _commonHashtags) {
      final keyword = normalizeSearchText(hashtag.substring(1)); // Remove #

      if (words.any((word) => word.contains(keyword)) &&
          !text.contains(hashtag)) {
        suggestions.add(SmartSuggestion(
          type: 'hashtag',
          text: text,
          suggestion: 'Add "$hashtag" hashtag',
          metadata: {'hashtag': hashtag, 'keyword': keyword},
        ));
      }
    }

    return suggestions;
  }

  /// Generate mention suggestions
  List<SmartSuggestion> _generateMentionSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];

    // Simple mention completion (in real app, this would query user database)
    final mentionPattern = RegExp(r'@(\w*)$');
    final match = mentionPattern.firstMatch(text);

    if (match != null) {
      final partial = normalizeSearchText(match.group(1) ?? '');
      final mockUsers = ['arkadas1', 'kullanici2', 'friend3'];

      for (final user in mockUsers) {
        if (normalizeSearchText(user).startsWith(partial)) {
          suggestions.add(SmartSuggestion(
            type: 'mention',
            text: text,
            suggestion: 'Complete mention: @$user',
            metadata: {'username': user, 'partial': partial},
          ));
        }
      }
    }

    return suggestions;
  }

  /// Generate grammar and spell check suggestions
  List<SmartSuggestion> _generateGrammarSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
    final normalizedText = normalizeSearchText(text);

    // Simple Turkish grammar checks
    final commonMistakes = {
      'degil': 'değil',
      'oldugu': 'olduğu',
      'vardir': 'vardır',
      'gercek': 'gerçek',
      'cok': 'çok',
      'kucuk': 'küçük',
      'buyuk': 'büyük',
    };

    for (final entry in commonMistakes.entries) {
      if (normalizedText.contains(normalizeSearchText(entry.key))) {
        suggestions.add(SmartSuggestion(
          type: 'grammar',
          text: text,
          suggestion: 'post_editing.replace_with'
              .trParams({'from': entry.key, 'to': entry.value}),
          metadata: {'original': entry.key, 'corrected': entry.value},
        ));
      }
    }

    return suggestions;
  }

  /// Generate content enhancement suggestions
  List<SmartSuggestion> _generateContentSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
    final normalizedText = normalizeSearchText(text);

    // Suggest adding location if not mentioned
    if (!RegExp(
      r'(konum|lokasyon|burada|here)',
    ).hasMatch(normalizedText)) {
      suggestions.add(SmartSuggestion(
        type: 'content',
        text: text,
        suggestion: 'post_editing.consider_location'.tr,
        metadata: {'type': 'location'},
      ));
    }

    // Suggest emojis based on content
    final emojiSuggestions = _suggestEmojis(text);
    suggestions.addAll(emojiSuggestions);

    // Length suggestions
    if (text.length < 20) {
      suggestions.add(SmartSuggestion(
        type: 'content',
        text: text,
        suggestion: 'Consider adding more details to your post',
        metadata: {'type': 'length', 'currentLength': text.length},
      ));
    } else if (text.length > 200) {
      suggestions.add(SmartSuggestion(
        type: 'content',
        text: text,
        suggestion: 'Consider shortening your post for better engagement',
        metadata: {'type': 'length', 'currentLength': text.length},
      ));
    }

    return suggestions;
  }

  /// Suggest emojis based on text content
  List<SmartSuggestion> _suggestEmojis(String text) {
    final suggestions = <SmartSuggestion>[];
    final lowerText = normalizeSearchText(text);

    final emojiMap = {
      'mutlu': '😊',
      'üzgün': '😢',
      'aşk': '❤️',
      'güzel': '😍',
      'yemek': '🍽️',
      'seyahat': '✈️',
      'doğa': '🌿',
      'güneş': '☀️',
      'ay': '🌙',
      'müzik': '🎵',
      'spor': '⚽',
      'kitap': '📚',
      'film': '🎬',
    };

    for (final entry in emojiMap.entries) {
      if (lowerText.contains(entry.key) && !text.contains(entry.value)) {
        suggestions.add(SmartSuggestion(
          type: 'emoji',
          text: text,
          suggestion: 'Add ${entry.value} emoji',
          metadata: {'emoji': entry.value, 'keyword': entry.key},
        ));
      }
    }

    return suggestions;
  }

  /// Apply suggestion to text
  String applySuggestion(String currentText, SmartSuggestion suggestion) {
    switch (suggestion.type) {
      case 'hashtag':
        final hashtag = suggestion.metadata['hashtag'] as String;
        return '$currentText $hashtag';

      case 'mention':
        final username = suggestion.metadata['username'] as String;
        final partial = suggestion.metadata['partial'] as String;
        return currentText.replaceAll('@$partial', '@$username');

      case 'grammar':
        final original = suggestion.metadata['original'] as String;
        final corrected = suggestion.metadata['corrected'] as String;
        return currentText.replaceAll(original, corrected);

      case 'emoji':
        final emoji = suggestion.metadata['emoji'] as String;
        return '$currentText $emoji';

      default:
        return currentText;
    }
  }

  /// Toggle smart suggestions
  void toggleSmartSuggestions() {
    _smartSuggestionsEnabled.value = !_smartSuggestionsEnabled.value;
    if (!_smartSuggestionsEnabled.value) {
      _suggestions.clear();
    }
  }

  /// Get formatting toolbar actions
  List<Map<String, dynamic>> getFormattingActions() {
    return [
      {
        'icon': Icons.format_bold,
        'label': 'post_editing.bold'.tr,
        'active': _currentFormatting.value.bold,
        'action': toggleBold,
      },
      {
        'icon': Icons.format_italic,
        'label': 'post_editing.italic'.tr,
        'active': _currentFormatting.value.italic,
        'action': toggleItalic,
      },
      {
        'icon': Icons.format_underlined,
        'label': 'post_editing.underline'.tr,
        'active': _currentFormatting.value.underline,
        'action': toggleUnderline,
      },
      {
        'icon': Icons.format_size,
        'label': 'post_editing.font_size'.tr,
        'active': false,
        'action': () => _showFontSizeDialog(),
      },
      {
        'icon': Icons.color_lens,
        'label': 'post_editing.text_color'.tr,
        'active': _currentFormatting.value.textColor != null,
        'action': () => _showColorPicker(),
      },
    ];
  }

  /// Show font size dialog
  void _showFontSizeDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('post_editing.font_size'.tr),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'post_editing.current_font_size'.trParams({
                    'size':
                        _currentFormatting.value.fontSize.toInt().toString(),
                  }),
                  style: TextStyle(fontSize: _currentFormatting.value.fontSize),
                ),
                Slider(
                  value: _currentFormatting.value.fontSize,
                  min: 10.0,
                  max: 24.0,
                  divisions: 14,
                  onChanged: changeFontSize,
                ),
              ],
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.done'.tr),
          ),
        ],
      ),
    );
  }

  /// Show color picker
  void _showColorPicker() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    Get.dialog(
      AlertDialog(
        title: Text('post_editing.text_color'.tr),
        content: Wrap(
          children: colors
              .map((color) => GestureDetector(
                    onTap: () {
                      changeTextColor(color);
                      Get.back();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _currentFormatting.value.textColor == color
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              changeTextColor(Colors.black);
              Get.back();
            },
            child: Text('common.reset'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.cancel'.tr),
          ),
        ],
      ),
    );
  }

  /// Get edit statistics
  Map<String, dynamic> getEditStatistics() {
    final now = DateTime.now();
    final recentActions = _undoStack
        .where((action) => now.difference(action.timestamp).inMinutes < 30)
        .length;

    final actionTypes = <String, int>{};
    for (final action in _undoStack) {
      actionTypes[action.type] = (actionTypes[action.type] ?? 0) + 1;
    }

    return {
      'totalActions': _undoStack.length,
      'recentActions': recentActions,
      'actionTypes': actionTypes,
      'canUndo': canUndo,
      'canRedo': canRedo,
      'suggestionsGenerated': _suggestions.length,
      'smartSuggestionsEnabled': _smartSuggestionsEnabled.value,
    };
  }
}
