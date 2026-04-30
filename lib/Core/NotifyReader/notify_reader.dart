// lib/DebugView.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_route_decision.dart';

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
    final decision = resolveLegacyNotifyReaderRoute(
      type: widget.type,
      docId: widget.docID,
    );
    if (!decision.canOpen) {
      Get.back();
      return;
    }

    switch (decision.action) {
      case NotifyReaderRouteAction.profile:
        controller.goToProfile(decision.targetId);
      case NotifyReaderRouteAction.post:
        controller.goToPost(decision.targetId);
      case NotifyReaderRouteAction.postComments:
        controller.goToPostComments(decision.targetId);
      case NotifyReaderRouteAction.chat:
        controller.goToChat(decision.targetId);
      case NotifyReaderRouteAction.market:
        controller.goToMarket(decision.targetId);
      case NotifyReaderRouteAction.job:
      case NotifyReaderRouteAction.tutoring:
      case NotifyReaderRouteAction.missing:
        Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
