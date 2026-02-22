import 'package:flutter/material.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:get/get.dart';
import '../Services/PostEditingService.dart';

class EnhancedTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int? maxLines;
  final int? maxLength;
  final bool showFormatting;
  final bool showSuggestions;
  final Function(String)? onChanged;

  const EnhancedTextEditor({
    super.key,
    required this.controller,
    this.hintText = 'Write something...',
    this.maxLines,
    this.maxLength,
    this.showFormatting = true,
    this.showSuggestions = true,
    this.onChanged,
  });

  @override
  State<EnhancedTextEditor> createState() => _EnhancedTextEditorState();
}

class _EnhancedTextEditorState extends State<EnhancedTextEditor> {
  late final PostEditingService _editingService;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editingService = Get.put(PostEditingService());
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _editingService.updateCurrentText(widget.controller.text);
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formatting toolbar
        if (widget.showFormatting) _buildFormattingToolbar(),

        // Text field
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Undo/Redo buttons
              _buildUndoRedoToolbar(),

              // Main text field
              Obx(() => TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                style: _editingService.currentFormatting.toTextStyle(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '', // Hide character counter
                ),
                onChanged: (text) {
                  final oldText = widget.controller.text;
                  _editingService.recordAction(
                    type: 'text_change',
                    beforeState: {'text': oldText},
                    afterState: {'text': text},
                  );
                  _onTextChanged();
                },
              )),

              // Character count
              if (widget.maxLength != null) _buildCharacterCount(),
            ],
          ),
        ),

        // Smart suggestions
        if (widget.showSuggestions) _buildSuggestions(),
      ],
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Obx(() {
        final actions = _editingService.getFormattingActions();
        return Row(
          children: actions.map((action) => _buildFormattingButton(
            icon: action['icon'] as IconData,
            label: action['label'] as String,
            isActive: action['active'] as bool,
            onPressed: action['action'] as VoidCallback,
          )).toList(),
        );
      }),
    );
  }

  Widget _buildFormattingButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          iconSize: 20,
          color: isActive ? Colors.blue : Colors.grey[600],
          splashRadius: 20,
        ),
      ),
    );
  }

  Widget _buildUndoRedoToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Obx(() => IconButton(
            icon: const Icon(Icons.undo, size: 18),
            onPressed: _editingService.canUndo ? _performUndo : null,
            color: _editingService.canUndo ? Colors.blue : Colors.grey,
            splashRadius: 18,
          )),
          Obx(() => IconButton(
            icon: const Icon(Icons.redo, size: 18),
            onPressed: _editingService.canRedo ? _performRedo : null,
            color: _editingService.canRedo ? Colors.blue : Colors.grey,
            splashRadius: 18,
          )),
          const Spacer(),
          // Smart suggestions toggle
          Obx(() => IconButton(
            icon: Icon(
              _editingService.smartSuggestionsEnabled
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
              size: 18,
            ),
            onPressed: _editingService.toggleSmartSuggestions,
            color: _editingService.smartSuggestionsEnabled
                ? Colors.blue
                : Colors.grey,
            splashRadius: 18,
          )),
        ],
      ),
    );
  }

  Widget _buildCharacterCount() {
    return Obx(() {
      final currentLength = widget.controller.text.length;
      final maxLength = widget.maxLength!;
      final isNearLimit = currentLength > maxLength * 0.8;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$currentLength/$maxLength',
              style: TextStyle(
                fontSize: 12,
                color: isNearLimit ? Colors.orange : Colors.grey[600],
                fontWeight: isNearLimit ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSuggestions() {
    return Obx(() {
      final suggestions = _editingService.suggestions;
      if (suggestions.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Suggestions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: suggestions.take(5).map((suggestion) =>
                _buildSuggestionChip(suggestion)
              ).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSuggestionChip(SmartSuggestion suggestion) {
    Color chipColor;
    IconData chipIcon;

    switch (suggestion.type) {
      case 'hashtag':
        chipColor = Colors.blue;
        chipIcon = Icons.tag;
        break;
      case 'mention':
        chipColor = Colors.green;
        chipIcon = Icons.alternate_email;
        break;
      case 'grammar':
        chipColor = Colors.orange;
        chipIcon = Icons.spellcheck;
        break;
      case 'emoji':
        chipColor = Colors.yellow;
        chipIcon = Icons.emoji_emotions;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.lightbulb_outline;
    }

    return ActionChip(
      avatar: Icon(chipIcon, size: 16, color: Colors.white),
      label: Text(
        suggestion.suggestion,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      onPressed: () => _applySuggestion(suggestion),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _performUndo() {
    final undoState = _editingService.undo();
    if (undoState != null && undoState.containsKey('text')) {
      widget.controller.text = undoState['text'] as String;
      _onTextChanged();
    }
  }

  void _performRedo() {
    final redoState = _editingService.redo();
    if (redoState != null && redoState.containsKey('text')) {
      widget.controller.text = redoState['text'] as String;
      _onTextChanged();
    }
  }

  void _applySuggestion(SmartSuggestion suggestion) {
    final currentText = widget.controller.text;
    final newText = _editingService.applySuggestion(currentText, suggestion);

    _editingService.recordAction(
      type: 'suggestion_applied',
      beforeState: {'text': currentText},
      afterState: {'text': newText},
    );

    widget.controller.text = newText;
    _onTextChanged();

    // Show feedback
    AppSnackbar(
      'Applied',
      suggestion.suggestion,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class FormattingToolbar extends StatelessWidget {
  final PostEditingService editingService;

  const FormattingToolbar({
    super.key,
    required this.editingService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() {
        final actions = editingService.getFormattingActions();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: actions.map((action) => IconButton(
            icon: Icon(action['icon'] as IconData),
            onPressed: action['action'] as VoidCallback,
            color: action['active'] as bool ? Colors.blue : Colors.grey[600],
            splashRadius: 20,
          )).toList(),
        );
      }),
    );
  }
}

class SuggestionPanel extends StatelessWidget {
  final PostEditingService editingService;
  final Function(SmartSuggestion) onSuggestionApplied;

  const SuggestionPanel({
    super.key,
    required this.editingService,
    required this.onSuggestionApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final suggestions = editingService.suggestions;
      if (suggestions.isEmpty) {
        return const Center(
          child: Text(
            'No suggestions available',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: _getSuggestionIcon(suggestion.type),
            title: Text(suggestion.suggestion),
            subtitle: Text(_getSuggestionDescription(suggestion)),
            onTap: () => onSuggestionApplied(suggestion),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        },
      );
    });
  }

  Widget _getSuggestionIcon(String type) {
    switch (type) {
      case 'hashtag':
        return const Icon(Icons.tag, color: Colors.blue);
      case 'mention':
        return const Icon(Icons.alternate_email, color: Colors.green);
      case 'grammar':
        return const Icon(Icons.spellcheck, color: Colors.orange);
      case 'emoji':
        return const Icon(Icons.emoji_emotions, color: Colors.yellow);
      default:
        return const Icon(Icons.lightbulb_outline, color: Colors.grey);
    }
  }

  String _getSuggestionDescription(SmartSuggestion suggestion) {
    switch (suggestion.type) {
      case 'hashtag':
        return 'Improve discoverability';
      case 'mention':
        return 'Tag a friend';
      case 'grammar':
        return 'Fix spelling/grammar';
      case 'emoji':
        return 'Add expression';
      default:
        return 'Enhance your content';
    }
  }
}