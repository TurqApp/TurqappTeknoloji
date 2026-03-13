import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class MyTestResultsController extends GetxController {
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    findAndGetTestler();
  }

  Future<void> findAndGetTestler() async {
    isLoading.value = true;
    list.clear();
    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      final items = await _testRepository.fetchAnsweredByUser(
        currentUserID,
        preferCache: true,
      );
      list.assignAll(items);
    } catch (e) {
      print("Error fetching test results: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
