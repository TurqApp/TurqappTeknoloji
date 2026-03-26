import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../Core/Services/giphy_picker_service.dart';
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/blocked_texts.dart';
import '../../../Core/functions.dart';
import '../../../Models/post_interactions_models_new.dart';
import '../../../Services/current_user_service.dart';
import '../../../Services/post_interaction_service.dart';

part 'post_comment_controller_actions_part.dart';
part 'post_comment_controller_facade_part.dart';
part 'post_comment_controller_fields_part.dart';
part 'post_comment_controller_runtime_part.dart';

class PostCommentController extends GetxController {
  static String? _activeTag;

  static PostCommentController ensure({
    required String postID,
    required String userID,
    required String collection,
    Function(bool increment)? onCommentCountChange,
    String? tag,
    bool permanent = false,
  }) =>
      _ensurePostCommentControllerFacade(
        postID: postID,
        userID: userID,
        collection: collection,
        onCommentCountChange: onCommentCountChange,
        tag: tag,
        permanent: permanent,
      );

  static PostCommentController? maybeFind({String? tag}) =>
      _maybeFindPostCommentControllerFacade(tag: tag);

  PostCommentController({
    required String postID,
    required String userID,
    required String collection,
    Function(bool increment)? onCommentCountChange,
  }) : _state = _PostCommentControllerState(
          postID: postID,
          userID: userID,
          collection: collection,
          onCommentCountChange: onCommentCountChange,
        );

  final _PostCommentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handlePostCommentControllerOnInit(this);
  }

  @override
  void onClose() {
    _handlePostCommentControllerOnClose(this);
    super.onClose();
  }
}
