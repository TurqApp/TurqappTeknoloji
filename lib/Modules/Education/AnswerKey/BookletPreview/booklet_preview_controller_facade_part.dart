part of 'booklet_preview_controller.dart';

class _BookletPreviewControllerState {
  _BookletPreviewControllerState({required this.model});

  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final BookletRepository bookletRepository = ensureBookletRepository();
  final UserSubcollectionRepository subcollectionRepository =
      ensureUserSubcollectionRepository();
  final BookletModel model;
  final RxBool isBookmarked = false.obs;
  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString fullName = ''.obs;
  final RxList<AnswerKeySubModel> answerKeys = <AnswerKeySubModel>[].obs;
}

class BookletPreviewController extends GetxController {
  final _BookletPreviewControllerState _state;

  BookletPreviewController(BookletModel model)
      : _state = _BookletPreviewControllerState(model: model);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }
}

extension BookletPreviewControllerFieldsPart on BookletPreviewController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  BookletRepository get _bookletRepository => _state.bookletRepository;
  UserSubcollectionRepository get _subcollectionRepository =>
      _state.subcollectionRepository;
  BookletModel get model => _state.model;
  RxBool get isBookmarked => _state.isBookmarked;
  RxString get nickname => _state.nickname;
  RxString get avatarUrl => _state.avatarUrl;
  RxString get fullName => _state.fullName;
  RxList<AnswerKeySubModel> get answerKeys => _state.answerKeys;
}

BookletPreviewController ensureBookletPreviewController(
  BookletModel model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindBookletPreviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    BookletPreviewController(model),
    tag: tag,
    permanent: permanent,
  );
}

BookletPreviewController? maybeFindBookletPreviewController({String? tag}) {
  final isRegistered = Get.isRegistered<BookletPreviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<BookletPreviewController>(tag: tag);
}

extension BookletPreviewControllerFacadePart on BookletPreviewController {
  void _initialize() => BookletPreviewControllerRuntimePart(this).initialize();

  Future<void> _loadBookmarkState(String currentUserId) =>
      BookletPreviewControllerRuntimePart(this)
          .loadBookmarkState(currentUserId);

  Future<void> fetchAnswerKeys() =>
      BookletPreviewControllerRuntimePart(this).fetchAnswerKeys();

  Future<void> fetchUserData() =>
      BookletPreviewControllerRuntimePart(this).fetchUserData();

  Future<void> toggleBookmark() =>
      BookletPreviewControllerRuntimePart(this).toggleBookmark();

  void navigateToAnswerKey(BuildContext context, AnswerKeySubModel subModel) {
    Get.to(() => BookletAnswer(model: subModel, anaModel: model));
  }
}
