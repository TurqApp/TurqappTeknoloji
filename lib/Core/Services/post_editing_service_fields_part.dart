part of 'post_editing_service.dart';

class _PostEditingServiceState {
  final RxList<EditAction> undoStack = <EditAction>[].obs;
  final RxList<EditAction> redoStack = <EditAction>[].obs;
  final Rx<TextFormatting> currentFormatting = TextFormatting().obs;
  final RxList<SmartSuggestion> suggestions = <SmartSuggestion>[].obs;
  final RxBool smartSuggestionsEnabled = true.obs;
  final RxString currentText = ''.obs;
}

extension PostEditingServiceFieldsPart on PostEditingService {
  RxList<EditAction> get _undoStack => _state.undoStack;
  RxList<EditAction> get _redoStack => _state.redoStack;
  Rx<TextFormatting> get _currentFormatting => _state.currentFormatting;
  RxList<SmartSuggestion> get _suggestions => _state.suggestions;
  RxBool get _smartSuggestionsEnabled => _state.smartSuggestionsEnabled;
  RxString get _currentText => _state.currentText;

  List<EditAction> get undoStack => _undoStack;
  List<EditAction> get redoStack => _redoStack;
  TextFormatting get currentFormatting => _currentFormatting.value;
  List<SmartSuggestion> get suggestions => _suggestions;
  bool get smartSuggestionsEnabled => _smartSuggestionsEnabled.value;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
}
