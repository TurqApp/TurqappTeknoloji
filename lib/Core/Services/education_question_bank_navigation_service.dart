import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/then_solve.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_soru_sonuclar.dart';

class EducationQuestionBankNavigationService {
  const EducationQuestionBankNavigationService();

  Future<void> openPastQuestionResults() async {
    await Get.to(() => const CikmisSoruSonuclar());
  }

  Future<void> openThenSolve() async {
    await Get.to(() => ThenSolve());
  }
}
