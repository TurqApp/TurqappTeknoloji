import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class SavedTestsController extends GetxController {
  final TestRepository _testRepository = TestRepository.ensure();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    list.clear();
    try {
      list.assignAll(
        await _testRepository.fetchFavorites(
          FirebaseAuth.instance.currentUser!.uid,
          preferCache: true,
        ),
      );
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
