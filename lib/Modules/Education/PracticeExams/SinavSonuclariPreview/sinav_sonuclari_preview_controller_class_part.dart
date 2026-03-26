part of 'sinav_sonuclari_preview_controller.dart';

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
    _handleInit();
  }

  Future<void> getYanitlar() => _loadAnswers();

  Future<void> getSorular() => _loadQuestions();

  Future<void> getDersVeSonuclar(String docID) => _loadLessonResults(docID);

  void toggleCategory(String ders) => _toggleCategory(ders);
}
