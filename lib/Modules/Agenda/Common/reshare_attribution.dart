import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/reshare_helper.dart';

import '../../../Models/posts_model.dart';
import 'post_content_controller.dart';

/// Displays who reshared the post, reusing logic for both agenda view styles.
class ReshareAttribution extends StatefulWidget {
  const ReshareAttribution({
    super.key,
    required this.controller,
    required this.model,
    this.explicitReshareUserId,
    this.style,
    this.placeholder = const SizedBox.shrink(),
  });

  final PostContentController controller;
  final PostsModel model;
  final String? explicitReshareUserId;
  final TextStyle? style;
  final Widget placeholder;

  @override
  State<ReshareAttribution> createState() => _ReshareAttributionState();
}

class _ReshareAttributionState extends State<ReshareAttribution> {
  Future<String>? _nicknameFuture;

  TextStyle get _labelStyle =>
      widget.style ??
      const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontFamily: 'MontserratMedium',
      );

  @override
  void initState() {
    super.initState();
    _prepareNicknameFuture();
  }

  @override
  void didUpdateWidget(covariant ReshareAttribution oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.explicitReshareUserId != widget.explicitReshareUserId) {
      _prepareNicknameFuture();
    }
  }

  void _prepareNicknameFuture() {
    _nicknameFuture = null;
    final targetId = widget.explicitReshareUserId;
    if (targetId == null) return;
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me != null && targetId == me) return;
    final cached = ReshareHelper.getCachedNickname(targetId);
    if (cached != null) return;
    _nicknameFuture = ReshareHelper.getUserNickname(targetId);
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;

    if (widget.explicitReshareUserId != null) {
      final targetId = widget.explicitReshareUserId!;
      if (me != null && targetId == me) {
        return Text('yeniden paylaştın', style: _labelStyle);
      }
      final cached = ReshareHelper.getCachedNickname(targetId);
      if (cached != null) {
        return Text('$cached yeniden paylaştı', style: _labelStyle);
      }
      return FutureBuilder<String>(
        future: _nicknameFuture,
        builder: (context, snapshot) {
          final name = snapshot.data?.trim().isNotEmpty == true
              ? snapshot.data!
              : 'Bir kullanıcı';
          return Text('$name yeniden paylaştı', style: _labelStyle);
        },
      );
    }

    return Obx(() {
      final uid = widget.controller.reShareUserUserID.value;
      if (uid.isEmpty) return widget.placeholder;
      if (me != null && uid == me) {
        return Text('yeniden paylaştın', style: _labelStyle);
      }
      final name = widget.controller.reShareUserNickname.value.isNotEmpty
          ? widget.controller.reShareUserNickname.value
          : 'Bir kullanıcı';
      return Text('$name yeniden paylaştı', style: _labelStyle);
    });
  }
}
