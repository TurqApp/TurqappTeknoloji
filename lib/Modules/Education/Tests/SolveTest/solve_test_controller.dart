import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';

class SolveTestController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
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
      print("Error fetching questions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserFullName() async {
    try {
      final data = await _userRepository.getUserRaw(
            FirebaseAuth.instance.currentUser!.uid,
          ) ??
          const <String, dynamic>{};
      final nick =
          (data["nickname"] ?? data["username"] ?? data["displayName"] ?? "")
              .toString()
              .trim();
      final firstName = (data["firstName"] ?? "").toString().trim();
      final lastName = (data["lastName"] ?? "").toString().trim();
      final fallbackName =
          [firstName, lastName].where((e) => e.isNotEmpty).join(" ").trim();
      fullname.value = nick.isNotEmpty ? nick : fallbackName;
    } catch (e) {
      print("Error fetching user data: $e");
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
      userId: FirebaseAuth.instance.currentUser!.uid,
      answers: cevaplar.toList(growable: false),
    )
        .catchError((error) {
      print("Yanitlar eklenirken hata: $error");
    });
    Get.back();
    showSucces();
  }
}
