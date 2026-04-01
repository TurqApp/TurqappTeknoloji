// lib/DebugView.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

import 'notify_reader_controller.dart';

class NotifyReader extends StatefulWidget {
  final String docID;
  final String type;
  const NotifyReader({super.key, required this.docID, required this.type});

  @override
  State<NotifyReader> createState() => _NotifyReaderState();
}

class _NotifyReaderState extends State<NotifyReader> {
  late final String _controllerTag;
  late final NotifyReaderController controller;
  bool _ownsController = false;
  bool _routed = false;
  static const _profileTypes = {'user', 'follow'};
  static const _postTypes = {
    'posts',
    'like',
    'reshared_posts',
    'shared_as_posts',
  };
  static const _chatTypes = {'chat', 'message'};
  static const _marketTypes = {'market_offer', 'market_offer_status'};

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'notify_reader_${widget.type}_${widget.docID}_${identityHashCode(this)}';
    final existingController = maybeFindNotifyReaderController(
      tag: _controllerTag,
    );
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureNotifyReaderController(tag: _controllerTag);
      _ownsController = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _routed) return;
      _routed = true;
      _routeByType();
    });
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindNotifyReaderController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<NotifyReaderController>(tag: _controllerTag);
    }
    super.dispose();
  }

  void _routeByType() {
    final rawType = widget.type.trim();
    final normalized = normalizeSearchText(rawType);

    if (widget.docID.trim().isEmpty) {
      Get.back();
      return;
    }

    if (_profileTypes.contains(normalized)) {
      controller.goToProfile(widget.docID);
      return;
    }
    if (_postTypes.contains(normalized)) {
      controller.goToPost(widget.docID);
      return;
    }
    if (normalized == "comment") {
      controller.goToPostComments(widget.docID);
      return;
    }
    if (_chatTypes.contains(normalized)) {
      controller.goToChat(widget.docID);
      return;
    }
    if (_marketTypes.contains(normalized)) {
      controller.goToMarket(widget.docID);
      return;
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
