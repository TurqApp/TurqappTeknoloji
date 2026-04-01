part of 'create_test_controller.dart';

extension CreateTestControllerDataPart on CreateTestController {
  Future<void> initializeData() async {
    isLoading.value = true;
    if (model != null) {
      testID.value = int.parse(model!.docID);
      selectedDers.assignAll(model!.dersler);
      aciklama.text = model!.aciklama;
      paylasilabilir.value = model!.paylasilabilir;
      foundImage.value = model!.img;
      testTuru.value = model!.testTuru;
      showSilButon.value = !model!.taslak;
      await getSorular();
    }
    await getUygulamaLinks();
    isLoading.value = false;
  }

  Future<void> getUygulamaLinks() async {
    try {
      final doc = await ensureConfigRepository().getLegacyConfigDoc(
        collection: 'Yönetim',
        docId: 'Genel',
        preferCache: true,
      );
      appStore.value = (doc?["appStore"] ?? "").toString();
      googlePlay.value = (doc?["googlePlay"] ?? "").toString();
    } catch (e) {
      print("Error fetching app links: $e");
    }
  }

  Future<void> getSorular() async {
    if (model == null) return;
    sorularList.clear();
    try {
      final questions = await _testRepository.fetchQuestions(
        model!.docID,
        preferCache: true,
      );
      if (questions.isEmpty) {
        sorularList.add(
          TestReadinessModel(
            id: 0,
            img: "",
            max: 5,
            dogruCevap: "",
            docID: "0",
          ),
        );
        return;
      }

      for (final question in questions) {
        sorularList.add(
          TestReadinessModel(
            id: question.id.toInt(),
            img: question.img,
            max: question.max.toInt(),
            dogruCevap: question.dogruCevap,
            docID: question.docID,
          ),
        );
      }
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  List<String> getFilteredDersler() {
    if (testTuru.value == createTestTypeMiddleSchool) {
      return [
        "Türkçe",
        "Matematik",
        "Fen Bilimleri",
        "İnkılap Tarihi",
        "Din Kültürü",
        "Yabancı Dil",
      ];
    }
    return tumDersler;
  }

  String localizedTestType(String raw) {
    switch (raw) {
      case createTestTypeMiddleSchool:
        return "tests.type.middle_school".tr;
      case createTestTypeHighSchool:
        return "tests.type.high_school".tr;
      case createTestTypePrep:
        return "tests.type.prep".tr;
      case createTestTypeLanguage:
        return "tests.type.language".tr;
      case createTestTypeBranch:
        return "tests.type.branch".tr;
      default:
        return raw;
    }
  }

  String localizedLesson(String raw) {
    switch (raw) {
      case "Türkçe":
        return "tests.lesson.turkish".tr;
      case "Edebiyat":
        return "tests.lesson.literature".tr;
      case "Matematik":
        return "tests.lesson.math".tr;
      case "Geometri":
        return "tests.lesson.geometry".tr;
      case "Fizik":
        return "tests.lesson.physics".tr;
      case "Kimya":
        return "tests.lesson.chemistry".tr;
      case "Biyoloji":
        return "tests.lesson.biology".tr;
      case "Tarih":
        return "tests.lesson.history".tr;
      case "Coğrafya":
        return "tests.lesson.geography".tr;
      case "Felsefe":
        return "tests.lesson.philosophy".tr;
      case "Psikoloji":
        return "tests.lesson.psychology".tr;
      case "Sosyoloji":
        return "tests.lesson.sociology".tr;
      case "Mantık":
        return "tests.lesson.logic".tr;
      case "Din Kültürü":
        return "tests.lesson.religion".tr;
      case "Fen Bilimleri":
        return "tests.lesson.science".tr;
      case "İnkılap Tarihi":
      case "İnkilap Tarihi":
        return "tests.lesson.revolution_history".tr;
      case "Yabancı Dil":
        return "tests.lesson.foreign_language".tr;
      case "Temel Matematik":
        return "tests.lesson.basic_math".tr;
      case "Sosyal Bilimler":
        return "tests.lesson.social_sciences".tr;
      case "Edebiyat - Sosyal Bilimler 1":
        return "tests.lesson.literature_social_1".tr;
      case "Sosyal Bilimler 2":
        return "tests.lesson.social_sciences_2".tr;
      case "Genel Yetenek":
        return "tests.lesson.general_ability".tr;
      case "Genel Kültür":
        return "tests.lesson.general_culture".tr;
      case "İngilizce":
        return "tests.language.english".tr;
      case "Almanca":
        return "tests.language.german".tr;
      case "Arapça":
        return "tests.language.arabic".tr;
      case "Fransızca":
        return "tests.language.french".tr;
      case "Rusça":
        return "tests.language.russian".tr;
      default:
        return raw;
    }
  }

  String localizedLessons(List<String> lessons) {
    return lessons.map(localizedLesson).join(", ");
  }

  IconData getIconForDers(String ders) {
    switch (ders) {
      case "Türkçe":
        return Icons.text_fields;
      case "Matematik":
        return Icons.calculate;
      case "Fizik":
        return Icons.science;
      case "İnkılap Tarihi":
        return Icons.history;
      case "Din Kültürü":
        return Icons.book;
      case "Yabancı Dil":
        return Icons.language;
      default:
        return Icons.help_outline;
    }
  }
}
