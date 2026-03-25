import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'create_book_controller_form_part.dart';
part 'create_book_controller_submission_part.dart';
part 'create_book_controller_answer_key_part.dart';
part 'create_book_controller_fields_part.dart';

class CreateBookController extends GetxController {
  static CreateBookController ensure(
    Function? onBack, {
    BookletModel? existingBook,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateBookController(onBack, existingBook: existingBook),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateBookController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateBookController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateBookController>(tag: tag);
  }

  final Function? onBack;
  final BookletModel? existingBook;
  late final String docID;
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final _state = _CreateBookControllerState();

  CreateBookController(this.onBack, {this.existingBook}) {
    docID =
        existingBook?.docID ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool get isEditMode => existingBook != null;

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    baslikController.dispose();
    yayinEviController.dispose();
    basimTarihiController.dispose();
    super.onClose();
  }

  void handleBack() {
    if (selection.value != 0) {
      selection.value--;
    } else {
      Get.back();
    }
  }

  void nextStep() {
    selection.value++;
  }

  void selectSinavTuru(String value) {
    sinavTuru.value = value;
  }
}
