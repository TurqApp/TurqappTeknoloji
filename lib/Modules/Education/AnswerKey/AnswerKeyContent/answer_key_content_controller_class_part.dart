part of 'answer_key_content_controller.dart';

class AnswerKeyContentController extends GetxController {
  static final Map<String, Set<String>> _savedIdsByUser =
      <String, Set<String>>{};
  static final Map<String, Future<Set<String>>> _savedIdsLoaders =
      <String, Future<Set<String>>>{};

  static AnswerKeyContentController ensure(
    BookletModel model,
    Function(bool) onUpdate, {
    String? tag,
    bool permanent = false,
  }) =>
      _ensureAnswerKeyContentController(model, onUpdate,
          tag: tag, permanent: permanent);

  static AnswerKeyContentController? maybeFind({String? tag}) =>
      _maybeFindAnswerKeyContentController(tag: tag);

  final _AnswerKeyContentControllerState _state;

  AnswerKeyContentController(BookletModel model, Function(bool) onUpdate)
      : _state = _AnswerKeyContentControllerState(
          model: model,
          onUpdate: onUpdate,
        );

  static String _resolveCurrentUid() =>
      _resolveAnswerKeyContentCurrentUidFacade();

  @override
  void onInit() {
    super.onInit();
    _handleAnswerKeyContentInit(this);
  }

  static Future<Set<String>> _loadSavedIds(String userId) =>
      _loadAnswerKeyContentSavedIdsFacade(userId);

  static Future<void> warmSavedIdsForCurrentUser() =>
      _warmAnswerKeyContentSavedIdsForCurrentUserFacade();
}
