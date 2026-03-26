part of 'tutoring_detail_controller.dart';

class _TutoringDetailControllerState {
  final isLoading = true.obs;
  final tutoring = buildEmptyTutoringModel().obs;
  final users = <String, Map<String, dynamic>>{}.obs;
  final carouselCurrentIndex = 0.obs;
  final basvuruldu = false.obs;
  final similarList = <TutoringModel>[].obs;
  final similarUsers = <String, Map<String, dynamic>>{}.obs;
  final reviews = <TutoringReviewModel>[].obs;
  final reviewUsers = <String, Map<String, dynamic>>{}.obs;
  final userSummaryResolver = UserSummaryResolver.ensure();
  final tutoringRepository = TutoringRepository.ensure();
}

extension TutoringDetailControllerFieldsPart on TutoringDetailController {
  RxBool get isLoading => _state.isLoading;
  Rx<TutoringModel> get tutoring => _state.tutoring;
  RxMap<String, Map<String, dynamic>> get users => _state.users;
  RxInt get carouselCurrentIndex => _state.carouselCurrentIndex;
  RxBool get basvuruldu => _state.basvuruldu;
  RxList<TutoringModel> get similarList => _state.similarList;
  RxMap<String, Map<String, dynamic>> get similarUsers => _state.similarUsers;
  RxList<TutoringReviewModel> get reviews => _state.reviews;
  RxMap<String, Map<String, dynamic>> get reviewUsers => _state.reviewUsers;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  TutoringRepository get _tutoringRepository => _state.tutoringRepository;
  String get _uid => CurrentUserService.instance.effectiveUserId;
}
