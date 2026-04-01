part of 'question_bank_snapshot_repository.dart';

class QuestionBankSnapshotRepository extends GetxService {
  QuestionBankSnapshotRepository();
  final _state = _QuestionBankSnapshotRepositoryState();

  static QuestionBankSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<QuestionBankSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<QuestionBankSnapshotRepository>();
  }

  static QuestionBankSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(QuestionBankSnapshotRepository(), permanent: true);
  }
}
