import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';

import '../../../Core/strings.dart';
import 'report_user_controller.dart';

part 'report_user_selection_part.dart';
part 'report_user_result_part.dart';

class ReportUser extends StatefulWidget {
  final String userID;
  final String postID;
  final String commentID;
  const ReportUser(
      {super.key,
      required this.userID,
      required this.postID,
      required this.commentID});

  @override
  State<ReportUser> createState() => _ReportUserState();
}

class _ReportUserState extends State<ReportUser> {
  late final ReportUserController controller;
  late final String _controllerTag;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'report_user_${widget.userID}_${widget.postID}_${widget.commentID}_${identityHashCode(this)}';
    final existingController =
        ReportUserController.maybeFind(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ReportUserController.ensure(
        userID: widget.userID,
        postID: widget.postID,
        commentID: widget.commentID,
        tag: _controllerTag,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          ReportUserController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ReportUserController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
