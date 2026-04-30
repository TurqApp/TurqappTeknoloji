part of 'booklet_preview_controller.dart';

class BookletPreviewControllerRuntimePart {
  const BookletPreviewControllerRuntimePart(this.controller);

  final BookletPreviewController controller;

  void initialize() {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    controller._loadBookmarkState(currentUserId);
    controller.fetchAnswerKeys();
    controller.fetchUserData();
  }

  Future<void> loadBookmarkState(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final savedDoc = await controller._subcollectionRepository.getEntry(
        currentUserId,
        subcollection: 'books',
        docId: controller.model.docID,
        preferCache: true,
      );
      controller.isBookmarked.value = savedDoc != null;
    } catch (_) {}
  }

  Future<void> fetchAnswerKeys() async {
    try {
      final rawItems = await controller._bookletRepository.fetchAnswerKeys(
        controller.model.docID,
        preferCache: true,
      );
      final newList = <AnswerKeySubModel>[];
      for (final item in rawItems) {
        final data = Map<String, dynamic>.from(
          (item['data'] as Map?) ?? const <String, dynamic>{},
        );
        final baslik = (data['baslik'] ?? '').toString();
        final rawCevaplar = data['dogruCevaplar'];
        final cevaplar = rawCevaplar is List
            ? rawCevaplar.map((e) => e.toString()).toList()
            : <String>[];
        final sira = data['sira'] is num
            ? data['sira'] as num
            : num.tryParse((data['sira'] ?? '0').toString()) ?? 0;

        newList.add(
          AnswerKeySubModel(
            baslik,
            (item['id'] ?? '').toString(),
            cevaplar,
            sira,
          ),
        );
      }
      newList.sort((a, b) => a.sira.compareTo(b.sira));
      controller.answerKeys.assignAll(newList);
    } catch (_) {}
  }

  Future<void> fetchUserData() async {
    try {
      final data = await controller._userSummaryResolver.resolve(
            controller.model.userID,
            preferCache: true,
          ) ??
          controller._userSummaryResolver.resolveFromMaps(
            controller.model.userID,
          );
      controller.nickname.value = data.nickname;
      controller.avatarUrl.value = data.avatarUrl;
      controller.fullName.value = data.displayName;
      if (controller.fullName.value.isEmpty) {
        controller.fullName.value = controller.nickname.value;
      }
    } catch (_) {}
  }

  Future<void> toggleBookmark() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) return;

    try {
      final savedDoc = await controller._subcollectionRepository.getEntry(
        userId,
        subcollection: 'books',
        docId: controller.model.docID,
        preferCache: true,
      );

      if (savedDoc != null) {
        await controller._subcollectionRepository.deleteEntry(
          userId,
          subcollection: 'books',
          docId: controller.model.docID,
        );
        controller.isBookmarked.value = false;
        return;
      }

      await controller._subcollectionRepository.upsertEntry(
        userId,
        subcollection: 'books',
        docId: controller.model.docID,
        data: <String, dynamic>{
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      controller.isBookmarked.value = true;
    } catch (_) {}
  }
}

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
    const AnswerKeyNavigationService().openBookletAnswer(
      model: subModel,
      anaModel: model,
    );
  }
}
