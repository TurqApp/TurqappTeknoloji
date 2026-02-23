import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/reshare_helper.dart';

import '../../../Models/posts_model.dart';
import 'post_content_controller.dart';

/// Displays who reshared the post, reusing logic for both agenda view styles.
class ReshareAttribution extends StatelessWidget {
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

  TextStyle get _labelStyle =>
      style ??
      const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontFamily: 'MontserratMedium',
      );

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;

    if (explicitReshareUserId != null) {
      final targetId = explicitReshareUserId!;
      if (me != null && targetId == me) {
        return Text('yeniden paylaştın', style: _labelStyle);
      }
      final cached = ReshareHelper.getCachedNickname(targetId);
      if (cached != null) {
        return Text('$cached yeniden paylaştı', style: _labelStyle);
      }
      return FutureBuilder<String>(
        future: ReshareHelper.getUserNickname(targetId),
        builder: (context, snapshot) {
          final name = snapshot.data?.trim().isNotEmpty == true
              ? snapshot.data!
              : 'Bir kullanıcı';
          return Text('$name yeniden paylaştı', style: _labelStyle);
        },
      );
    }

    return Obx(() {
      final uid = controller.reShareUserUserID.value;
      if (uid.isEmpty) return placeholder;
      if (me != null && uid == me) {
        return Text('yeniden paylaştın', style: _labelStyle);
      }
      final name = controller.reShareUserNickname.value.isNotEmpty
          ? controller.reShareUserNickname.value
          : 'Bir kullanıcı';
      return Text('$name yeniden paylaştı', style: _labelStyle);
    });
  }
}
