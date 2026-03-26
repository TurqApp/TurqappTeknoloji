part of 'enhanced_text_editor.dart';

extension _EnhancedTextEditorLifecyclePart on _EnhancedTextEditorState {
  void _initEnhancedTextEditorLifecycle() {
    super.initState();
    _editingService = ensurePostEditingService();
    widget.controller.addListener(_onTextChangedLifecycle);
  }

  void _disposeEnhancedTextEditorLifecycle() {
    widget.controller.removeListener(_onTextChangedLifecycle);
    _focusNode.dispose();
  }

  void _onTextChangedLifecycle() {
    _editingService.updateCurrentText(widget.controller.text);
    widget.onChanged?.call(widget.controller.text);
  }
}
