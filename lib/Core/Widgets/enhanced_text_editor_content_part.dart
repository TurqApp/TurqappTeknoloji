part of 'enhanced_text_editor.dart';

extension _EnhancedTextEditorContentPart on _EnhancedTextEditorState {
  Widget _buildEnhancedTextEditorContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showFormatting) _buildFormattingToolbar(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildUndoRedoToolbar(),
              Obx(
                () => TextField(
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
                    counterText: '',
                  ),
                  onChanged: (text) {
                    final oldText = widget.controller.text;
                    _editingService.recordAction(
                      type: 'text_change',
                      beforeState: {'text': oldText},
                      afterState: {'text': text},
                    );
                    _onTextChangedLifecycle();
                  },
                ),
              ),
              if (widget.maxLength != null) _buildCharacterCount(),
            ],
          ),
        ),
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
          children: actions
              .map(
                (action) => _buildFormattingButton(
                  icon: action['icon'] as IconData,
                  label: action['label'] as String,
                  isActive: action['active'] as bool,
                  onPressed: action['action'] as VoidCallback,
                ),
              )
              .toList(),
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
          Obx(
            () => IconButton(
              icon: const Icon(Icons.undo, size: 18),
              onPressed: _editingService.canUndo ? _performUndoAction : null,
              color: _editingService.canUndo ? Colors.blue : Colors.grey,
              splashRadius: 18,
            ),
          ),
          Obx(
            () => IconButton(
              icon: const Icon(Icons.redo, size: 18),
              onPressed: _editingService.canRedo ? _performRedoAction : null,
              color: _editingService.canRedo ? Colors.blue : Colors.grey,
              splashRadius: 18,
            ),
          ),
          const Spacer(),
          Obx(
            () => IconButton(
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
            ),
          ),
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
              children: suggestions
                  .take(5)
                  .map((suggestion) => _buildSuggestionChip(suggestion))
                  .toList(),
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
      onPressed: () => _applySuggestionAction(suggestion),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
