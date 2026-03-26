part of 'antreman_controller.dart';

class AntremanController extends GetxController {
  static AntremanController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AntremanController(), permanent: permanent);
  }

  static AntremanController? maybeFind() {
    final isRegistered = Get.isRegistered<AntremanController>();
    if (!isRegistered) return null;
    return Get.find<AntremanController>();
  }

  final QuestionBankSnapshotRepository _questionBankSnapshotRepository =
      QuestionBankSnapshotRepository.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final Map<String, Map<String, List<String>>> subjects = _antremanSubjects;

  final Map<String, IconData> icons = _antremanIcons;
  final _state = _AntremanControllerState();

  final String userID = CurrentUserService.instance.effectiveUserId;
  final int batchSize = 5;

  @override
  void onInit() {
    super.onInit();
    loadMainCategory();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
