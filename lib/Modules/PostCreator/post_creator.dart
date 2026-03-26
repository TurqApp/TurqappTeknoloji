import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/PostCreator/CreatorContent/creator_content_controller.dart';
import 'package:turqappv2/Modules/PostCreator/CreatorContent/post_creator_model.dart';
import 'CreatorContent/creator_content.dart';
import 'post_creator_controller.dart';
import '../../Core/BottomSheets/no_yes_alert.dart';
import '../../Core/Services/integration_test_keys.dart';
import '../../Core/Widgets/app_header_action_button.dart';
import '../../Core/Widgets/app_icon_surface.dart';
import '../../Core/Widgets/progress_indicators.dart';

part 'post_creator_shell_part.dart';
part 'post_creator_body_part.dart';
part 'post_creator_toolbar_part.dart';

class PostCreator extends StatelessWidget {
  final String routeInstanceId = UniqueKey().toString();
  final String sharedVideoUrl;
  final List<String> sharedImageUrls;
  final double sharedAspectRatio;
  final String sharedThumbnail;
  final bool sharedAsPost;
  final String? originalUserID;
  final String? originalPostID;
  final String? sourcePostID;
  final bool quotedPost;
  final String? quotedOriginalText;
  final String? quotedSourceUserID;
  final String? quotedSourceDisplayName;
  final String? quotedSourceUsername;
  final String? quotedSourceAvatarUrl;
  final bool editMode;
  final PostsModel? editPost;

  PostCreator({
    super.key,
    this.sharedVideoUrl = '',
    this.sharedImageUrls = const <String>[],
    this.sharedAspectRatio = 9 / 16,
    this.sharedThumbnail = '',
    this.sharedAsPost = false,
    this.originalUserID,
    this.originalPostID,
    this.sourcePostID,
    this.quotedPost = false,
    this.quotedOriginalText,
    this.quotedSourceUserID,
    this.quotedSourceDisplayName,
    this.quotedSourceUsername,
    this.quotedSourceAvatarUrl,
    this.editMode = false,
    this.editPost,
  });
  final controller = PostCreatorController.ensure();
  final progressController = ensureUploadProgressController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: controller.prepareForRoute(
        routeId: routeInstanceId,
        sharedAsPost: sharedAsPost,
        editMode: editMode,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
          );
        }
        controller.applySharedSourceIfNeeded(
          videoUrl: sharedVideoUrl,
          imageUrls: sharedImageUrls,
          aspectRatio: sharedAspectRatio,
          thumbnail: sharedThumbnail,
          sharedAsPost: sharedAsPost,
          originalUserID: originalUserID,
          originalPostID: originalPostID,
          sourcePostID: sourcePostID,
          quotedPost: quotedPost,
          quotedOriginalText: quotedOriginalText,
          quotedSourceUserID: quotedSourceUserID,
          quotedSourceDisplayName: quotedSourceDisplayName,
          quotedSourceUsername: quotedSourceUsername,
          quotedSourceAvatarUrl: quotedSourceAvatarUrl,
        );
        controller.applyEditSourceIfNeeded(
          editMode: editMode,
          editPost: editPost,
        );
        return _buildPage(context);
      },
    );
  }
}
