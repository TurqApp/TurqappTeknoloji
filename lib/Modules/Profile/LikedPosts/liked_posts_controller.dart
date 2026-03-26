import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content_controller.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

part 'liked_posts_controller_lifecycle_part.dart';
part 'liked_posts_controller_data_part.dart';
part 'liked_posts_controller_fields_part.dart';
part 'liked_posts_controller_facade_part.dart';
part 'liked_posts_controller_navigation_part.dart';

class LikedPostControllers extends GetxController {
  static LikedPostControllers ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(LikedPostControllers());
  }

  static LikedPostControllers? maybeFind() {
    final isRegistered = Get.isRegistered<LikedPostControllers>();
    if (!isRegistered) return null;
    return Get.find<LikedPostControllers>();
  }

  static bool isSeriesPost(PostsModel post) => post.floodCount > 1;

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _LikedPostsControllerState();

  final UserPostLinkService _linkService = UserPostLinkService.ensure();

  @override
  void onInit() {
    super.onInit();
    _LikedPostsControllerLifecyclePart(this).handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await _LikedPostsControllerDataPart(this).refreshLikedPosts();
  }

  @override
  void onClose() {
    _LikedPostsControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
