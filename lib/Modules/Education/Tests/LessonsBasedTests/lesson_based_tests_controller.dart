import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class LessonBasedTestsController extends GetxController {
  final TestRepository _testRepository = TestRepository.ensure();
  final String testTuru;
  final list = <TestsModel>[].obs;
  final isLoading = false.obs;

  LessonBasedTestsController(this.testTuru);

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      list.assignAll(await _testRepository.fetchByType(testTuru, preferCache: true));
    } finally {
      isLoading.value = false;
    }
  }
}
