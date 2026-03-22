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

part 'create_test_controller_actions_part.dart';
part 'create_test_controller_data_part.dart';

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
    final isRegistered = Get.isRegistered<CreateTestController>(tag: tag);
    if (!isRegistered) return null;
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
}
