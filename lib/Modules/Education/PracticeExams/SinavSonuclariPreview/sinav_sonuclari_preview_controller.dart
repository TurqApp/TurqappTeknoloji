import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

class SinavSonuclariPreviewController extends GetxController {
  static SinavSonuclariPreviewController ensure({
    required String tag,
    required SinavModel model,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SinavSonuclariPreviewController(model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static SinavSonuclariPreviewController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<SinavSonuclariPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SinavSonuclariPreviewController>(tag: tag);
  }

  var yanitlar = <String>[].obs;
  var timeStamp = (0 as num).obs;
  var soruList = <SoruModel>[].obs;
  var expandedCategories = <String, bool>{}.obs;
  var dersVeSonuclar = <DersVeSonuclarDB>[].obs;
  var yanitID = "".obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final SinavModel model;
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  SinavSonuclariPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    getYanitlar();
  }

  Future<void> getYanitlar() async {
    isLoading.value = true;
    try {
      final snapshot = await _practiceExamRepository.fetchAnswers(
        model.docID,
        preferCache: true,
      );

      if (snapshot.isNotEmpty) {
        snapshot.sort(
          (a, b) => ((a['timeStamp'] ?? 0) as num)
              .compareTo((b['timeStamp'] ?? 0) as num),
        );
        final latest = snapshot.last;
        final yanitlarData = List<String>.from(latest['yanitlar'] ?? const []);
        final timeStampData = (latest["timeStamp"] ?? 0) as num;
        final yanitIDData = (latest["_docId"] ?? latest["id"] ?? "").toString();

        yanitlar.assignAll(yanitlarData);
        timeStamp.value = timeStampData;
        yanitID.value = yanitIDData;

        await getSorular();
      } else {
        isLoading.value = false;
        isInitialized.value = true;
      }
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.answers_load_failed'.tr);
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getSorular() async {
    try {
      final questions = await _practiceExamRepository.fetchQuestions(
        model.docID,
        preferCache: true,
      );

      if (questions.isNotEmpty) {
        for (final question in questions) {
          if (!expandedCategories.containsKey(question.ders)) {
            expandedCategories[question.ders] = false;
          }
        }
        soruList.assignAll(questions);
        await getDersVeSonuclar(yanitID.value);
      }
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.questions_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getDersVeSonuclar(String docID) async {
    try {
      final results = await _practiceExamRepository.fetchLessonResults(
        model.docID,
        docID,
        model.dersler,
      );
      dersVeSonuclar.assignAll(results);
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.lesson_results_load_failed'.tr);
    }
  }

  void toggleCategory(String ders) {
    expandedCategories[ders] = !expandedCategories[ders]!;
  }
}
