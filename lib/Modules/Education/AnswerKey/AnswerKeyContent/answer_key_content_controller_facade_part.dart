part of 'answer_key_content_controller.dart';

AnswerKeyContentController _ensureAnswerKeyContentController(
  BookletModel model,
  Function(bool) onUpdate, {
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindAnswerKeyContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    AnswerKeyContentController(model, onUpdate),
    tag: tag,
    permanent: permanent,
  );
}

AnswerKeyContentController? _maybeFindAnswerKeyContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<AnswerKeyContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<AnswerKeyContentController>(tag: tag);
}

String _resolveAnswerKeyContentCurrentUidFacade() =>
    _resolveAnswerKeyContentCurrentUid();

void _syncAnswerKeyContentModel(
  AnswerKeyContentController controller,
  BookletModel nextModel,
) {
  controller.model = nextModel;
}

void _handleAnswerKeyContentInit(AnswerKeyContentController controller) {
  controller._initialize();
}

Future<Set<String>> _loadAnswerKeyContentSavedIdsFacade(String userId) =>
    _loadAnswerKeyContentSavedIds(userId);

Future<void> _warmAnswerKeyContentSavedIdsForCurrentUserFacade() =>
    _warmAnswerKeyContentSavedIdsForCurrentUser();
