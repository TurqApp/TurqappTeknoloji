import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'booklet_answer_controller_data_part.dart';
part 'booklet_answer_controller_actions_part.dart';

class BookletAnswerController extends GetxController {
  static BookletAnswerController ensure(
    AnswerKeySubModel model,
    BookletModel anaModel, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BookletAnswerController(model, anaModel),
      tag: tag,
      permanent: permanent,
    );
  }

  static BookletAnswerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<BookletAnswerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BookletAnswerController>(tag: tag);
  }

  final ConfigRepository _configRepository = ConfigRepository.ensure();
  final AnswerKeySubModel model;
  final BookletModel anaModel;

  final cevaplar = <String>[].obs;
  final completed = false.obs;
  final correctCount = 0.obs;
  final wrongCount = 0.obs;
  final emptyCount = 0.obs;
  final scorePercent = 0.0.obs;
  final netScore = 0.0.obs;
  final isInterstitialAdReady = false.obs;
  final iosList = ''.obs;
  final androidList = ''.obs;

  BookletAnswerController(this.model, this.anaModel);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}
