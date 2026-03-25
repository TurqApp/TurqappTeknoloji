import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/Education/tutoring_review_model.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'tutoring_detail_controller_reviews_part.dart';
part 'tutoring_detail_controller_runtime_part.dart';
part 'tutoring_detail_controller_actions_part.dart';
part 'tutoring_detail_controller_models_part.dart';

class TutoringDetailController extends GetxController {
  static TutoringDetailController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TutoringDetailController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TutoringDetailController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TutoringDetailController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TutoringDetailController>(tag: tag);
  }

  var isLoading = true.obs;
  var tutoring = buildEmptyTutoringModel().obs;
  var users = <String, Map<String, dynamic>>{}.obs;
  var carouselCurrentIndex = 0.obs;

  // Application state
  final basvuruldu = false.obs;

  // Similar listings
  final similarList = <TutoringModel>[].obs;
  final similarUsers = <String, Map<String, dynamic>>{}.obs;

  // Reviews
  final reviews = <TutoringReviewModel>[].obs;
  final reviewUsers = <String, Map<String, dynamic>>{}.obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();

  String get _uid => CurrentUserService.instance.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    final tutoringData = Get.arguments as TutoringModel?;
    if (tutoringData != null) {
      _TutoringDetailControllerRuntimeX(this).bootstrap(tutoringData);
    }
  }

  Future<void> fetchUserData(String userID) =>
      _TutoringDetailControllerRuntimeX(this).fetchUserData(userID);

  Future<void> fetchTutoringDetail(String docID) =>
      _TutoringDetailControllerRuntimeX(this).fetchTutoringDetail(docID);

  // ── Application ──

  Future<void> checkBasvuru(String docID) =>
      _TutoringDetailControllerRuntimeX(this).checkBasvuru(docID);

  Future<void> toggleBasvuru(String docId) =>
      _TutoringDetailControllerActionsX(this).toggleBasvuru(docId);

  // ── View Count ──

  // ── Unpublish ──

  Future<void> unpublishTutoring() =>
      _TutoringDetailControllerActionsX(this).unpublishTutoring();

  // ── Similar ──

  Future<void> getSimilar(String brans, String currentDocID) =>
      _TutoringDetailControllerRuntimeX(this).getSimilar(brans, currentDocID);
}
