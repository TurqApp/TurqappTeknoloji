import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultPreview/booklet_result_preview.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclariPreview/sinav_sonuclari_preview.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview.dart';

class EducationResultNavigationService {
  const EducationResultNavigationService();

  Future<void> openBookletResultPreview(BookletResultModel model) async {
    await Get.to(() => BookletResultPreview(model: model));
  }

  Future<void> openTestPastResultPreview(TestsModel model) async {
    await Get.to(() => MyPastTestResultsPreview(model: model));
  }

  Future<void> openPracticeExamResultPreview(SinavModel model) async {
    await Get.to(() => SinavSonuclariPreview(model: model));
  }
}
