import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/AddTestQuestion/add_test_question.dart';
import 'package:turqappv2/Services/current_user_service.dart';

const createTestTypeMiddleSchool = 'Ortaokul';
const createTestTypeHighSchool = 'Lise';
const createTestTypePrep = 'Hazırlık';
const createTestTypeLanguage = 'Dil';
const createTestTypeBranch = 'Branş';

class CreateTestController extends GetxController {
  static CreateTestController ensure(
    TestsModel? model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateTestController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateTestController? maybeFind({String? tag}) {
    if (!Get.isRegistered<CreateTestController>(tag: tag)) return null;
    return Get.find<CreateTestController>(tag: tag);
  }

  final TestsModel? model;
  final aciklama = TextEditingController();
  final selectedDers = <String>[].obs;
  final showBransh = false.obs;
  final showDiller = false.obs;
  final selectedDil = ''.obs;
  final testTuru = 'Lise'.obs;
  final paylasilabilir = true.obs;
  final check = false.obs;
  final imageFile = Rx<File?>(null);
  final foundImage = ''.obs;
  final picker = ImagePicker();
  final appStore = ''.obs;
  final googlePlay = ''.obs;
  final testID = DateTime.now().millisecondsSinceEpoch.obs;
  final showSilButon = false.obs;
  final kopyalandi = false.obs;
  final sorularList = <TestReadinessModel>[
    TestReadinessModel(id: 0, img: "", max: 5, dogruCevap: "", docID: "0"),
  ].obs;
  final isLoading = true.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  CreateTestController(this.model);

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  @override
  void onClose() {
    aciklama.dispose();
    super.onClose();
  }

  void initializeData() async {
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
      final doc = await ConfigRepository.ensure().getLegacyConfigDoc(
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
      } else {
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
      }
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      imageFile.value = pickedFile;
      await analyzeImage();
    }
  }

  Future<void> analyzeImage() async {
    if (imageFile.value == null) return;
    try {
      final detector = await NsfwDetector.load(threshold: 0.3);
      final result = await detector.detectNSFWFromFile(imageFile.value!);
      print("NSFW detected: ${result?.isNsfw}");
      print("NSFW score: ${result?.score}");
      if (result == null || result.isNsfw) {
        imageFile.value = null;
      }
    } catch (e) {
      print("Error analyzing image: $e");
      imageFile.value = null;
    }
  }

  Future<void> yukle(File imageFile) async {
    try {
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: imageFile,
        storagePathWithoutExt:
            'Testler/${testID.value}/${DateTime.now().millisecondsSinceEpoch}',
      );
      await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID.value.toString())
          .set({"img": downloadUrl}, SetOptions(merge: true));
      SetOptions(merge: true);
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void deleteTest() {
    FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .delete();
    Get.back();
  }

  void saveTest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .update({
      "aciklama": aciklama.text,
      "dersler": selectedDers.toList(),
      "paylasilabilir": paylasilabilir.value,
      "testTuru": testTuru.value,
    });
    if (imageFile.value != null) {
      await yukle(imageFile.value!);
    }
    Get.back();
  }

  void prepareTest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .set({
      "aciklama": aciklama.text,
      "dersler": selectedDers.toList(),
      "favoriler": [],
      "paylasilabilir": paylasilabilir.value,
      "timeStamp": DateTime.now().millisecondsSinceEpoch.toString(),
      "userID": CurrentUserService.instance.userId,
      "taslak": true,
      "testTuru": testTuru.value,
    }, SetOptions(merge: true));
    if (imageFile.value != null) {
      await yukle(imageFile.value!);
    }
    Get.to(
      () => AddTestQuestion(
        soruList: sorularList,
        testID: testID.value.toString(),
        update: () => Get.back(),
        testTuru: testTuru.value,
      ),
    );
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
