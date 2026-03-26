part of 'enhanced_text_editor.dart';

class _EnhancedTextEditorState extends State<EnhancedTextEditor> {
  late final PostEditingService _editingService;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() => _initEnhancedTextEditorLifecycle();

  @override
  void dispose() {
    _disposeEnhancedTextEditorLifecycle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _buildEnhancedTextEditorContent(context);

  void _onTextChanged() => _onTextChangedLifecycle();

  void _performUndo() => _performUndoAction();

  void _performRedo() => _performRedoAction();

  void _applySuggestion(SmartSuggestion suggestion) =>
      _applySuggestionAction(suggestion);
}
