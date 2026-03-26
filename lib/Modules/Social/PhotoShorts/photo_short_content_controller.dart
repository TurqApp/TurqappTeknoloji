import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../Models/posts_model.dart';
import '../../../Services/reshare_helper.dart';
import '../../../Services/post_count_manager.dart';
import '../../../Services/post_interaction_service.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Profile/MyProfile/profile_controller.dart';
import '../../ShareGrid/share_grid.dart';
import '../../Short/short_controller.dart';
import '../Comments/post_comments.dart';
import '../../../Services/post_delete_service.dart';
import '../../../Core/Services/admin_access_service.dart';
import '../../../Core/Repositories/post_repository.dart';
import '../../../Core/Repositories/admin_push_repository.dart';
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/Services/typesense_post_service.dart';
import '../../../Services/current_user_service.dart';

part 'photo_short_content_controller_post_part.dart';
part 'photo_short_content_controller_fields_part.dart';
part 'photo_short_content_controller_runtime_part.dart';
part 'photo_short_content_controller_social_part.dart';

class PhotoShortsContentController extends GetxController {
  static PhotoShortsContentController ensure({
    required PostsModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PhotoShortsContentController(model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static PhotoShortsContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<PhotoShortsContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PhotoShortsContentController>(tag: tag);
  }

  PostsModel model;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final _state = _PhotoShortsControllerState();

  PhotoShortsContentController({required this.model});

  @override
  void onInit() {
    super.onInit();
    _initializeRuntime();
  }

  @override
  void onClose() {
    _disposeRuntime();
    super.onClose();
  }
}
