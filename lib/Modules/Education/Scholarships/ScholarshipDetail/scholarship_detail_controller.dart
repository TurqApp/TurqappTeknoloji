import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'scholarship_detail_controller_data_part.dart';
part 'scholarship_detail_controller_actions_part.dart';
part 'scholarship_detail_controller_facade_part.dart';

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
