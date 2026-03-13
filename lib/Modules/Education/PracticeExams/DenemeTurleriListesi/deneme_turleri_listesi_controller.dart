import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeTurleriListesiController extends GetxController {
  var list = <SinavModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final String sinavTuru;
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  DenemeTurleriListesiController({required this.sinavTuru});

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      final items = await _practiceExamRepository.fetchByExamType(
        sinavTuru,
        preferCache: true,
      );
      list.assignAll(items);
    } catch (error) {
      AppSnackbar("Hata", "Sınavlar yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }
}
