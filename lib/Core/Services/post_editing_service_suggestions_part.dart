part of 'post_editing_service.dart';

extension PostEditingServiceSuggestionsPart on PostEditingService {
  void _startSuggestionGeneration() {
    ever(_currentText, (String text) {
      if (_smartSuggestionsEnabled.value && text.isNotEmpty) {
        _generateSuggestions(text);
      }
    });
  }

  void updateCurrentText(String text) {
    _currentText.value = text;
  }

  void _generateSuggestions(String text) {
    _suggestions.clear();

    final hashtagSuggestions = _generateHashtagSuggestions(text);
    _suggestions.addAll(hashtagSuggestions);

    if (text.contains('@')) {
      final mentionSuggestions = _generateMentionSuggestions(text);
      _suggestions.addAll(mentionSuggestions);
    }

    final grammarSuggestions = _generateGrammarSuggestions(text);
    _suggestions.addAll(grammarSuggestions);

    final contentSuggestions = _generateContentSuggestions(text);
    _suggestions.addAll(contentSuggestions);
  }

  List<SmartSuggestion> _generateHashtagSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
    final normalizedText = normalizeSearchText(text);
    final words = normalizedText.split(' ');

    for (final hashtag in PostEditingService._commonHashtags) {
      final keyword = normalizeSearchText(hashtag.substring(1));

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

  List<SmartSuggestion> _generateMentionSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
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

  List<SmartSuggestion> _generateGrammarSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
    final normalizedText = normalizeSearchText(text);

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

  List<SmartSuggestion> _generateContentSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
    final normalizedText = normalizeSearchText(text);

    if (!RegExp(r'(konum|lokasyon|burada|here)').hasMatch(normalizedText)) {
      suggestions.add(SmartSuggestion(
        type: 'content',
        text: text,
        suggestion: 'post_editing.consider_location'.tr,
        metadata: {'type': 'location'},
      ));
    }

    final emojiSuggestions = _suggestEmojis(text);
    suggestions.addAll(emojiSuggestions);

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

  void toggleSmartSuggestions() {
    _smartSuggestionsEnabled.value = !_smartSuggestionsEnabled.value;
    if (!_smartSuggestionsEnabled.value) {
      _suggestions.clear();
    }
  }

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
