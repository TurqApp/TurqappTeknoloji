import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';

part 'create_test_question_content_controller_actions_part.dart';
part 'create_test_question_content_controller_data_part.dart';

class CreateTestQuestionContentController extends GetxController {
  static CreateTestQuestionContentController ensure({
    required TestReadinessModel model,
    required String testID,
    required int index,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateTestQuestionContentController(
        model: model,
        testID: testID,
        index: index,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateTestQuestionContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<CreateTestQuestionContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateTestQuestionContentController>(tag: tag);
  }

  final TestReadinessModel model;
  final String testID;
  final int index;
  final selectedImage = Rx<File?>(null);
  final focunImage = ''.obs;
  final selection = 5.obs;
  final dogruCevap = ''.obs;
  final selections = ['A'].obs;
  final isLoading = false.obs;
  final isInvalid = false.obs;

  CreateTestQuestionContentController({
    required this.model,
    required this.testID,
    required this.index,
  });
}
