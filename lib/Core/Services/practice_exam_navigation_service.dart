import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class PracticeExamNavigationService {
  const PracticeExamNavigationService();

  Future<void> openSearchPracticeExams() async {
    await Get.to(() => SearchDeneme());
  }

  Future<void> openCreatePracticeExam({SinavModel? model}) async {
    await Get.to(() => SinavHazirla(sinavModel: model));
  }

  Future<void> openMyPracticeExamResults() async {
    await Get.to(() => SinavSonuclarim());
  }

  Future<void> openMyPracticeExams() async {
    await Get.to(() => const MyPracticeExams());
  }

  Future<void> openSavedPracticeExams() async {
    await Get.to(() => const SavedPracticeExams());
  }

  Future<void> openPreview(SinavModel model) async {
    await Get.to(() => DenemeSinaviPreview(model: model));
  }
}
