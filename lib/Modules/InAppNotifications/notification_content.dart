import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_controller.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'notification_content_controller.dart';

part 'notification_content_body_part.dart';
part 'notification_content_actions_part.dart';

class NotificationContent extends StatefulWidget {
  final NotificationModel model;
  final VoidCallback? onOpen;
  final VoidCallback? onCardTap;
  const NotificationContent({
    super.key,
    required this.model,
    this.onOpen,
    this.onCardTap,
  });

  @override
  State<NotificationContent> createState() => _NotificationContentState();
}

class _NotificationContentState extends State<NotificationContent> {
  late NotificationContentController controller;
  late String _controllerTag;
  bool _ownsController = false;

  NotificationModel get model => widget.model;
  VoidCallback? get onOpen => widget.onOpen;
  VoidCallback? get onCardTap => widget.onCardTap;

  @override
  void initState() {
    super.initState();
    _bindController();
    _primePostData();
  }

  @override
  void didUpdateWidget(covariant NotificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.docID != widget.model.docID ||
        oldWidget.model.postID != widget.model.postID ||
        oldWidget.model.userID != widget.model.userID ||
        oldWidget.model.postType != widget.model.postType) {
      _disposeController();
      _bindController();
    }
    _primePostData();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _bindController() {
    _controllerTag =
        'notification_content_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindNotificationContentController(tag: _controllerTag) == null;
    controller = ensureNotificationContentController(
      userID: widget.model.userID,
      notification: widget.model,
      tag: _controllerTag,
    );
  }

  void _disposeController() {
    if (_ownsController &&
        identical(
          maybeFindNotificationContentController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<NotificationContentController>(
        tag: _controllerTag,
        force: true,
      );
    }
  }

  void _primePostData() {
    if (model.postType == kNotificationPostTypePosts &&
        controller.model.value.docID != model.postID) {
      controller.getPostData(model.postID);
    }
  }

  String _buildPrimaryText() {
    final base = model.desc.trim().isEmpty
        ? "notification.item.default_interaction".tr
        : model.desc.trim();
    return base.endsWith(".") ? base : "$base.";
  }

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  List<String> get _mediaPreviewUrls {
    final urls = <String>[];

    void addUrl(String rawUrl) {
      final normalized = CdnUrlBuilder.toCdnUrl(rawUrl.trim());
      if (normalized.isEmpty || urls.contains(normalized)) return;
      urls.add(normalized);
    }

    addUrl(model.thumbnail);
    for (final url in controller.model.value.preferredVideoPosterUrls) {
      addUrl(url);
    }
    for (final url in controller.model.value.img) {
      addUrl(url);
    }

    return urls;
  }

  @override
  Widget build(BuildContext context) {
    return _buildNotificationCard(context);
  }
}
