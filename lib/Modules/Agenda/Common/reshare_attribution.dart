import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';
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
  String? _resolvedNickname;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

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
    _resolvedNickname = null;
    final targetId = widget.explicitReshareUserId;
    if (targetId == null) return;
    final me = _currentUid;
    if (me.isNotEmpty && targetId == me) return;
    final cached = ReshareHelper.getCachedNickname(targetId);
    if (cached != null && cached.trim().isNotEmpty) {
      _resolvedNickname = cached.trim();
      return;
    }
    _loadNickname(targetId);
  }

  Future<void> _loadNickname(String userId) async {
    final summary = await _userSummaryResolver.resolve(
      userId,
      preferCache: true,
    );
    if (!mounted) return;
    final resolved = summary?.nickname.trim().isNotEmpty == true
        ? summary!.nickname.trim()
        : summary?.preferredName.trim() ?? '';
    if (resolved.isEmpty) return;
    ReshareHelper.cacheNickname(userId, resolved);
    setState(() {
      _resolvedNickname = resolved;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.model.originalUserID.trim().isNotEmpty) {
      return widget.placeholder;
    }

    final me = _currentUid;

    if (widget.explicitReshareUserId != null) {
      final targetId = widget.explicitReshareUserId!.trim();
      if (targetId.isEmpty) return widget.placeholder;
      if (me.isNotEmpty && targetId == me) {
        return Text('post.reshared_you'.tr, style: _labelStyle);
      }
      final cached = ReshareHelper.getCachedNickname(targetId);
      if (cached != null && !ReshareHelper.isUnknownUserLabel(cached)) {
        return Text(
          'post.reshared_by'.trParams({'name': cached}),
          style: _labelStyle,
        );
      }
      final name = _resolvedNickname?.trim() ?? '';
      if (ReshareHelper.isUnknownUserLabel(name)) {
        return widget.placeholder;
      }
      return Text(
        'post.reshared_by'.trParams({'name': name}),
        style: _labelStyle,
      );
    }

    return Obx(() {
      final uid = widget.controller.reShareUserUserID.value;
      if (uid.isEmpty) {
        if (widget.controller.yenidenPaylasildiMi.value) {
          return Text('post.reshared_you'.tr, style: _labelStyle);
        }
        return widget.placeholder;
      }
      if (me.isNotEmpty && uid == me) {
        return Text('post.reshared_you'.tr, style: _labelStyle);
      }
      final name = widget.controller.reShareUserNickname.value.trim();
      if (ReshareHelper.isUnknownUserLabel(name)) {
        return widget.placeholder;
      }
      return Text(
        'post.reshared_by'.trParams({'name': name}),
        style: _labelStyle,
      );
    });
  }
}
