part of 'story_interaction_optimizer.dart';

class _StoryInteractionOptimizerState {
  final userService = CurrentUserService.instance;
  Timer? writeTimer;
  final pendingWrites = <String, int>{};
  final pendingUsers = <String>{};
  bool isWriting = false;
  final pendingOperations = <Future<void>>[];
  final localStoryCache = <String, bool>{}.obs;
  final localTimeCache = <String, int>{}.obs;
  StreamSubscription? userSubscription;
}

extension StoryInteractionOptimizerFieldsPart on StoryInteractionOptimizer {
  CurrentUserService get _userService => _state.userService;
  Timer? get _writeTimer => _state.writeTimer;
  set _writeTimer(Timer? value) => _state.writeTimer = value;
  Map<String, int> get _pendingWrites => _state.pendingWrites;
  Set<String> get _pendingUsers => _state.pendingUsers;
  bool get _isWriting => _state.isWriting;
  set _isWriting(bool value) => _state.isWriting = value;
  List<Future<void>> get _pendingOperations => _state.pendingOperations;
  RxMap<String, bool> get localStoryCache => _state.localStoryCache;
  RxMap<String, int> get localTimeCache => _state.localTimeCache;
  StreamSubscription? get _userSubscription => _state.userSubscription;
  set _userSubscription(StreamSubscription? value) =>
      _state.userSubscription = value;
}
