part of 'enhanced_text_editor.dart';

extension _EnhancedTextEditorActionsPart on _EnhancedTextEditorState {
  void _performUndoAction() {
    final undoState = _editingService.undo();
    if (undoState != null && undoState.containsKey('text')) {
      widget.controller.text = undoState['text'] as String;
      _onTextChangedLifecycle();
    }
  }

  void _performRedoAction() {
    final redoState = _editingService.redo();
    if (redoState != null && redoState.containsKey('text')) {
      widget.controller.text = redoState['text'] as String;
      _onTextChangedLifecycle();
    }
  }

  void _applySuggestionAction(SmartSuggestion suggestion) {
    final currentText = widget.controller.text;
    final newText = _editingService.applySuggestion(currentText, suggestion);

    _editingService.recordAction(
      type: 'suggestion_applied',
      beforeState: {'text': currentText},
      afterState: {'text': newText},
    );

    widget.controller.text = newText;
    _onTextChangedLifecycle();

    AppSnackbar(
      'common.success'.tr,
      suggestion.suggestion,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
