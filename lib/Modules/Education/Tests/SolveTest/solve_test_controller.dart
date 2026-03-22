import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'solve_test_controller_data_part.dart';
part 'solve_test_controller_actions_part.dart';

class SolveTestController extends GetxController {
  static SolveTestController ensure({
    required String testID,
    required Function showSucces,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SolveTestController(
        testID: testID,
        showSucces: showSucces,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static SolveTestController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SolveTestController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SolveTestController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TestRepository _testRepository = TestRepository.ensure();
  final String testID;
  final Function showSucces;
  final soruList = <TestReadinessModel>[].obs;
  final selections = ['A'].obs;
  final cevap = ''.obs;
  final cevaplar = <String>[].obs;
  final elapsedTime = Duration.zero.obs;
  final fullname = ''.obs;
  final isLoading = true.obs;
  late DateTime _startTime;
  late Timer _timer;

  SolveTestController({required this.testID, required this.showSucces});

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
