part of 'antreman_controller.dart';

mixin _AntremanControllerBasePart on GetxController {
  final QuestionBankSnapshotRepository _questionBankSnapshotRepository =
      QuestionBankSnapshotRepository.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final Map<String, Map<String, List<String>>> subjects = _antremanSubjects;

  final Map<String, IconData> icons = _antremanIcons;
  final _state = _AntremanControllerState();

  final String userID = CurrentUserService.instance.effectiveUserId;
  final int batchSize = 5;
}
