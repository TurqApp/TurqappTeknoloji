part of 'post_editing_service.dart';

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
    '#fotograf',
    '#video',
    '#muzik',
    '#sanat',
    '#seyahat',
    '#yemek',
    '#spor',
    '#teknoloji',
    '#kitap',
    '#film',
    '#doga',
    '#arkadas'
  ];

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
