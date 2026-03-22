import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'dart:io';

part 'add_test_question_controller_actions_part.dart';
part 'add_test_question_controller_data_part.dart';

const _addQuestionMiddleSchoolType = 'Ortaokul';

class AddTestQuestionController extends GetxController {
  static AddTestQuestionController ensure({
    required List<TestReadinessModel> initialSoruList,
    required String testID,
    required String testTuru,
    required Function onUpdate,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AddTestQuestionController(
        initialSoruList: initialSoruList,
        testID: testID,
        testTuru: testTuru,
        onUpdate: onUpdate,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static AddTestQuestionController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AddTestQuestionController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AddTestQuestionController>(tag: tag);
  }

  final List<TestReadinessModel> initialSoruList;
  final String testID;
  final String testTuru;
  final Function onUpdate;
  final soruList = <TestReadinessModel>[].obs;
  final selectedImage = Rx<File?>(null);
  final dogruCevap = ''.obs;
  final selection = 5.obs;
  final selections = ['A'].obs;
  final isLoading = true.obs;
  final ImagePicker picker = ImagePicker();
  final TestRepository _testRepository = TestRepository.ensure();

  AddTestQuestionController({
    required this.initialSoruList,
    required this.testID,
    required this.testTuru,
    required this.onUpdate,
  });

  @override
  void onInit() {
    super.onInit();
    soruList.assignAll(initialSoruList);
    getSorular();
  }
}
