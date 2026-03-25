part of 'story_maker_controller.dart';

class _StoryMakerControllerState {
  final color = Colors.transparent.obs;
  final elements = <StoryElement>[].obs;
  final music = ''.obs;
  final selectedMusic = Rxn<MusicModel>();
  final isDragging = false.obs;
  StoryElement? draggedElement;
  final isElementOverTrash = false.obs;
  Offset? lastFingerPosition;
  int colorIndex = 0;
  int zIndexCounter = 0;
  String sharedPostSeedFingerprint = '';
  final history = <List<StoryElement>>[];
  int historyIndex = -1;
  final maxHistorySize = 20;
  final canUndo = false.obs;
  final canRedo = false.obs;
  final audioPlayer = AudioPlayer();
  final isMusicPlaying = false.obs;
}

extension StoryMakerControllerFieldsPart on StoryMakerController {
  Rx<Color> get color => _state.color;
  RxList<StoryElement> get elements => _state.elements;
  RxString get music => _state.music;
  Rxn<MusicModel> get selectedMusic => _state.selectedMusic;
  RxBool get isDragging => _state.isDragging;
  StoryElement? get draggedElement => _state.draggedElement;
  set draggedElement(StoryElement? value) => _state.draggedElement = value;
  RxBool get isElementOverTrash => _state.isElementOverTrash;
  Offset? get lastFingerPosition => _state.lastFingerPosition;
  set lastFingerPosition(Offset? value) => _state.lastFingerPosition = value;
  int get _colorIndex => _state.colorIndex;
  set _colorIndex(int value) => _state.colorIndex = value;
  int get _zIndexCounter => _state.zIndexCounter;
  set _zIndexCounter(int value) => _state.zIndexCounter = value;
  String get _sharedPostSeedFingerprint => _state.sharedPostSeedFingerprint;
  set _sharedPostSeedFingerprint(String value) =>
      _state.sharedPostSeedFingerprint = value;
  List<List<StoryElement>> get _history => _state.history;
  int get _historyIndex => _state.historyIndex;
  set _historyIndex(int value) => _state.historyIndex = value;
  int get _maxHistorySize => _state.maxHistorySize;
  RxBool get canUndo => _state.canUndo;
  RxBool get canRedo => _state.canRedo;
  AudioPlayer get _audioPlayer => _state.audioPlayer;
  RxBool get isMusicPlaying => _state.isMusicPlaying;
}
