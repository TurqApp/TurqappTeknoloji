import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'create_answer_key_controller_fields_part.dart';
part 'create_answer_key_controller_facade_part.dart';
part 'create_answer_key_controller_runtime_part.dart';

class CreateAnswerKeyController extends GetxController {
  static CreateAnswerKeyController ensure(
    Function onBack, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateAnswerKeyController(onBack),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateAnswerKeyController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateAnswerKeyController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateAnswerKeyController>(tag: tag);
  }

  final _CreateAnswerKeyControllerState _state;

  CreateAnswerKeyController(Function onBack)
      : _state = _CreateAnswerKeyControllerState(onBack: onBack);

  @override
  void onClose() {
    _disposeCreateAnswerKeyController(this);
    super.onClose();
  }
}
