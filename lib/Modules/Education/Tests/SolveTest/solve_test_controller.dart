import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SolveTestController extends GetxController {
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
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime.value = DateTime.now().difference(_startTime);
    });
    getSorular();
    getUserFullName();
  }

  @override
  void onClose() {
    _timer.cancel();
    super.onClose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> getSorular() async {
    isLoading.value = true;
    try {
      soruList.assignAll(
        await _testRepository.fetchQuestions(
          testID,
          preferCache: true,
        ),
      );
      cevaplar.assignAll(List.generate(soruList.length, (index) => ""));
    } catch (e) {
      soruList.clear();
      cevaplar.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserFullName() async {
    try {
      final summary = await _userSummaryResolver.resolve(
        CurrentUserService.instance.userId,
        preferCache: true,
      );
      fullname.value = summary?.preferredName ?? "";
    } catch (e) {
      fullname.value = "";
    }
  }

  void updateAnswer(int index, String choice) {
    cevaplar[index] = choice;
  }

  void testiBitir() {
    _testRepository
        .submitAnswers(
      testID,
      userId: CurrentUserService.instance.userId,
      answers: cevaplar.toList(growable: false),
    )
        .catchError((error) {});
    Get.back();
    showSucces();
  }
}
