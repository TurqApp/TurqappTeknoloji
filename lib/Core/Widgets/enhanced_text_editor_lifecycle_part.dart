part of 'enhanced_text_editor.dart';

abstract class _EnhancedTextEditorStateBase extends State<EnhancedTextEditor> {
  late final PostEditingService _editingService;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editingService = ensurePostEditingService();
    widget.controller.addListener(_onTextChangedLifecycle);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChangedLifecycle);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChangedLifecycle() {
    _editingService.updateCurrentText(widget.controller.text);
    widget.onChanged?.call(widget.controller.text);
  }
}
