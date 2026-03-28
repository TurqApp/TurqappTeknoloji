part of 'post_repository.dart';

class _PostRepositoryFieldsState {
  final TypesensePostService typesensePostService =
      TypesensePostService.instance;
  final Map<String, PostRepositoryState> states =
      <String, PostRepositoryState>{};
  final Map<String, List<PostSharersModel>> postSharersMemory =
      <String, List<PostSharersModel>>{};
  final UserSubcollectionRepository userSubcollectionRepository =
      ensureUserSubcollectionRepository();
  SharedPreferences? prefs;
}

extension PostRepositoryFieldsPart on PostRepository {
  TypesensePostService get _typesensePostService => _state.typesensePostService;
  Map<String, PostRepositoryState> get _states => _state.states;
  Map<String, List<PostSharersModel>> get _postSharersMemory =>
      _state.postSharersMemory;
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
}
