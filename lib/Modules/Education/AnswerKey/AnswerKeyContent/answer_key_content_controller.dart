import 'dart:async';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'answer_key_content_controller_data_part.dart';
part 'answer_key_content_controller_actions_part.dart';
part 'answer_key_content_controller_runtime_part.dart';

class AnswerKeyContentController extends GetxController {
  static final Map<String, Set<String>> _savedIdsByUser =
      <String, Set<String>>{};
  static final Map<String, Future<Set<String>>> _savedIdsLoaders =
      <String, Future<Set<String>>>{};
  static AnswerKeyContentController ensure(
    BookletModel model,
    Function(bool) onUpdate, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AnswerKeyContentController(model, onUpdate),
      tag: tag,
      permanent: permanent,
    );
  }

  static AnswerKeyContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AnswerKeyContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AnswerKeyContentController>(tag: tag);
  }

  BookletModel model;
  final Function(bool) onUpdate;

  final isBookmarked = false.obs;
  final secim = ''.obs;

  AnswerKeyContentController(this.model, this.onUpdate);
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static String _resolveCurrentUid() => _resolveAnswerKeyContentCurrentUid();

  bool get isOwner => isCurrentUserId(model.userID);

  void syncModel(BookletModel nextModel) {
    model = nextModel;
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  static Future<Set<String>> _loadSavedIds(String userId) =>
      _loadAnswerKeyContentSavedIds(userId);

  static Future<void> warmSavedIdsForCurrentUser() =>
      _warmAnswerKeyContentSavedIdsForCurrentUser();
}
