import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletAnswer/booklet_answer.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'booklet_preview_controller_runtime_part.dart';

class BookletPreviewController extends GetxController {
  static BookletPreviewController ensure(
    BookletModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BookletPreviewController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static BookletPreviewController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<BookletPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BookletPreviewController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final BookletModel model;

  final isBookmarked = false.obs;
  final nickname = ''.obs;
  final avatarUrl = ''.obs;
  final fullName = ''.obs;
  final answerKeys = <AnswerKeySubModel>[].obs;

  BookletPreviewController(this.model);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() => BookletPreviewControllerRuntimePart(this).initialize();

  Future<void> _loadBookmarkState(String currentUserId) =>
      BookletPreviewControllerRuntimePart(this)
          .loadBookmarkState(currentUserId);

  Future<void> fetchAnswerKeys() =>
      BookletPreviewControllerRuntimePart(this).fetchAnswerKeys();

  Future<void> fetchUserData() =>
      BookletPreviewControllerRuntimePart(this).fetchUserData();

  Future<void> toggleBookmark() =>
      BookletPreviewControllerRuntimePart(this).toggleBookmark();

  void navigateToAnswerKey(BuildContext context, AnswerKeySubModel subModel) {
    Get.to(() => BookletAnswer(model: subModel, anaModel: model));
  }
}
