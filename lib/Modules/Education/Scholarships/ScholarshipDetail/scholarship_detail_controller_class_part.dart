part of 'scholarship_detail_controller.dart';

class ScholarshipDetailController extends GetxController {
  static ScholarshipDetailController ensure({bool permanent = false}) =>
      _ensureScholarshipDetailController(permanent: permanent);

  static ScholarshipDetailController? maybeFind() =>
      _maybeFindScholarshipDetailController();

  static const String _selectValue = 'Seçiniz';
  static const String _selectActionValue = 'Seçim Yap';
  static const String _selectJobValue = 'Meslek Seç';
  static const String _yesValue = 'Evet';
  static const String _middleSchool = 'Ortaokul';
  static const String _highSchool = 'Lise';
  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  var showAllUniversities = false.obs;
  var hiddenUniversityCount = 0.obs;
  var isLoading = false.obs;
  var isFollowing = false.obs;
  var currentPageIndex = 0.obs;
  final RxBool applyReady = false.obs;
  final RxBool allreadyApplied = false.obs;
  final Rxn<IndividualScholarshipsModel> resolvedModel =
      Rxn<IndividualScholarshipsModel>();
  final RxBool detailLoading = false.obs;
  String? _followInitForId;

  @override
  void onInit() {
    super.onInit();
    _handleScholarshipDetailInit(this);
  }

  void updatePageIndex(int pageIndex) =>
      _updateScholarshipDetailPageIndex(this, pageIndex);

  void toggleUniversityList() => _toggleScholarshipUniversityList(this);

  String formatTimestamp(int? timestamp) =>
      _formatScholarshipDetailTimestamp(timestamp);

  final RxBool isFollowLoading = false.obs;
}
