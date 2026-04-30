import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTestResults/my_test_results.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTests/my_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/SavedTests/saved_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/SearchTests/search_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test.dart';
import 'package:turqappv2/Modules/Education/Tests/TestEntry/test_entry.dart';

class EducationTestNavigationService {
  const EducationTestNavigationService();

  Future<void> openSearchTests() async {
    await Get.to(() => SearchTests());
  }

  Future<void> openSavedTests() async {
    await Get.to(() => SavedTests());
  }

  Future<void> openMyTestResults() async {
    await Get.to(() => MyTestResults());
  }

  Future<void> openMyTests() async {
    await Get.to(() => MyTests());
  }

  Future<void> openCreateTest({TestsModel? model}) async {
    await Get.to(() => CreateTest(model: model));
  }

  Future<void> openTestEntry() async {
    await Get.to(() => TestEntry());
  }

  Future<void> openSolveTest({
    required String testID,
    required Function showSucces,
  }) async {
    await Get.to(
      () => SolveTest(testID: testID, showSucces: showSucces),
    );
  }
}
