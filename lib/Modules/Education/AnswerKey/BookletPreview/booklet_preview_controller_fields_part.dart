part of 'booklet_preview_controller.dart';

class _BookletPreviewControllerState {
  _BookletPreviewControllerState({required this.model});

  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final BookletRepository bookletRepository = ensureBookletRepository();
  final UserSubcollectionRepository subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final BookletModel model;
  final RxBool isBookmarked = false.obs;
  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString fullName = ''.obs;
  final RxList<AnswerKeySubModel> answerKeys = <AnswerKeySubModel>[].obs;
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
