import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class TestPastResultContentController extends GetxController {
  final TestsModel model;
  final count = 0.obs;
  final isLoading = true.obs;
  final timeStamp = 0.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  TestPastResultContentController(this.model);

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    count.value = 0;
    timeStamp.value = 0;
    try {
      final snapshot = await _testRepository.fetchAnswers(
        model.docID,
        preferCache: true,
      );
      final filtered = snapshot
          .where(
            (doc) =>
                (doc["userID"] ?? "").toString() ==
                FirebaseAuth.instance.currentUser!.uid,
          )
          .toList(growable: false)
        ..sort(
          (a, b) => ((b["timeStamp"] ?? 0) as num)
              .compareTo((a["timeStamp"] ?? 0) as num),
        );

      if (filtered.isNotEmpty) {
        count.value = filtered.length;
        timeStamp.value = ((filtered.first["timeStamp"] ?? 0) as num).toInt();
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
