import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import '../Agenda/agenda_controller.dart';
import '../Profile/MyProfile/profile_controller.dart';
import '../ShareGrid/share_grid.dart';
import '../../Services/post_delete_service.dart';
import 'short_controller.dart';
import '../../Services/post_interaction_service.dart';
import '../../Core/Repositories/post_repository.dart';
import '../../Core/Repositories/follow_repository.dart';
import '../../Core/Services/user_summary_resolver.dart';
import '../../Services/current_user_service.dart';

part 'short_content_controller_data_part.dart';
part 'short_content_controller_actions_part.dart';
part 'short_content_controller_fields_part.dart';
part 'short_content_controller_runtime_part.dart';
part 'short_content_controller_support_part.dart';

class ShortContentController extends GetxController {
  static ShortContentController ensure({
    required String postID,
    required PostsModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ShortContentController(postID: postID, model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static ShortContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ShortContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ShortContentController>(tag: tag);
  }

  ShortContentController({
    required String postID,
    required PostsModel model,
  }) : _state = _ShortContentControllerState(postID: postID, model: model);
  final _ShortContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleRuntimeInit();
  }

  @override
  void onClose() {
    _handleRuntimeClose();
    super.onClose();
  }
}
