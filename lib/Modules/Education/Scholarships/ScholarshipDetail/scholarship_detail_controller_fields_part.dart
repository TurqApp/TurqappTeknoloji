part of 'scholarship_detail_controller_library.dart';

class _ScholarshipDetailControllerState {
  final UserRepository userRepository = UserRepository.ensure();
  final ScholarshipRepository scholarshipRepository =
      ensureScholarshipRepository();
  final FollowRepository followRepository = ensureFollowRepository();
  final RxBool showAllUniversities = false.obs;
  final RxInt hiddenUniversityCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isFollowing = false.obs;
  final RxInt currentPageIndex = 0.obs;
  final RxBool applyReady = false.obs;
  final RxBool allreadyApplied = false.obs;
  final Rxn<IndividualScholarshipsModel> resolvedModel =
      Rxn<IndividualScholarshipsModel>();
  final RxBool detailLoading = false.obs;
  final RxBool isFollowLoading = false.obs;
  String? followInitForId;
}

extension ScholarshipDetailControllerFieldsPart on ScholarshipDetailController {
  UserRepository get _userRepository => _state.userRepository;
  ScholarshipRepository get _scholarshipRepository =>
      _state.scholarshipRepository;
  FollowRepository get _followRepository => _state.followRepository;
  RxBool get showAllUniversities => _state.showAllUniversities;
  RxInt get hiddenUniversityCount => _state.hiddenUniversityCount;
  RxBool get isLoading => _state.isLoading;
  RxBool get isFollowing => _state.isFollowing;
  RxInt get currentPageIndex => _state.currentPageIndex;
  RxBool get applyReady => _state.applyReady;
  RxBool get allreadyApplied => _state.allreadyApplied;
  Rxn<IndividualScholarshipsModel> get resolvedModel => _state.resolvedModel;
  RxBool get detailLoading => _state.detailLoading;
  RxBool get isFollowLoading => _state.isFollowLoading;
  String? get _followInitForId => _state.followInitForId;
  set _followInitForId(String? value) => _state.followInitForId = value;
}
