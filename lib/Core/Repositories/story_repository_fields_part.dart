part of 'story_repository.dart';

class _StoryRepositoryState {
  final UserRepository userRepository = UserRepository.ensure();
  final VisibilityPolicyService visibilityPolicy =
      VisibilityPolicyService.ensure();
  String? storyRowCacheDirectoryPath;
  SharedPreferences? prefs;
}

extension StoryRepositoryFieldsPart on StoryRepository {
  UserRepository get _userRepository => _state.userRepository;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  String? get _storyRowCacheDirectoryPath => _state.storyRowCacheDirectoryPath;
  set _storyRowCacheDirectoryPath(String? value) =>
      _state.storyRowCacheDirectoryPath = value;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
}
