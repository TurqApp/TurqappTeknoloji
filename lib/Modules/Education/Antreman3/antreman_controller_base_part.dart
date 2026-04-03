part of 'antreman_controller.dart';

abstract class _AntremanControllerBase extends GetxController {
  final QuestionBankSnapshotRepository _questionBankSnapshotRepository =
      QuestionBankSnapshotRepository.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final Map<String, Map<String, List<String>>> subjects = _antremanSubjects;

  final Map<String, IconData> icons = _antremanIcons;
  final _state = _AntremanControllerState();

  final String userID = CurrentUserService.instance.effectiveUserId;
  final int initialBatchSize = 10;
  final int batchSize = 5;
  final int prefetchRemainingThreshold = 5;

  @override
  void onInit() {
    super.onInit();
    _antremanInit(this as AntremanController);
  }

  @override
  void onClose() {
    _antremanClose(this as AntremanController);
    super.onClose();
  }
}
