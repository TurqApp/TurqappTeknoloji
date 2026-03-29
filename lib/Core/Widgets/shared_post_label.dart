import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/app_tokens.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/reshare_helper.dart';

class SharedPostLabel extends StatefulWidget {
  final String originalUserID;
  final String sourceUserID;
  final String labelSuffix;
  final Color textColor;
  final double fontSize;
  final bool showBackdrop;

  const SharedPostLabel({
    super.key,
    required this.originalUserID,
    this.sourceUserID = '',
    this.labelSuffix = '',
    this.textColor = Colors.grey,
    this.fontSize = 12,
    this.showBackdrop = false,
  });

  @override
  State<SharedPostLabel> createState() => _SharedPostLabelState();
}

class _SharedPostLabelState extends State<SharedPostLabel> {
  String? _displayName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  @override
  void didUpdateWidget(SharedPostLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalUserID != widget.originalUserID ||
        oldWidget.sourceUserID != widget.sourceUserID) {
      _loadDisplayName();
    }
  }

  String get _effectiveUserID {
    final source = widget.sourceUserID.trim();
    if (source.isNotEmpty) return source;
    return widget.originalUserID.trim();
  }

  void _loadDisplayName() async {
    final effectiveUserID = _effectiveUserID;
    if (effectiveUserID.isEmpty) {
      return;
    }

    // Önce cache'ten kontrol et
    final cachedName = ReshareHelper.getCachedNickname(effectiveUserID);

    if (cachedName != null) {
      // Cache'te var, direkt kullan
      if (mounted) {
        setState(() {
          _displayName = cachedName;
          _isLoading = false;
        });
      }
    } else {
      // Cache'te yok, yükle (sadece bir kez)
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
        });

        try {
          final displayName =
              await ReshareHelper.getUserNickname(effectiveUserID);
          if (mounted) {
            setState(() {
              _displayName = displayName.trim().isNotEmpty &&
                      !ReshareHelper.isUnknownUserLabel(displayName)
                  ? displayName
                  : null;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _displayName = null;
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yeniden paylaşım yoksa hiçbir şey gösterme
    final effectiveUserID = _effectiveUserID;
    if (effectiveUserID.isEmpty) {
      return const SizedBox.shrink();
    }

    // Nickname yok ve yükleniyor da değilse hiçbir şey gösterme
    if (_displayName == null && !_isLoading) {
      return const SizedBox.shrink();
    }

    // Nickname varsa göster
    if (_displayName != null) {
      final useBackdrop =
          widget.showBackdrop || widget.textColor == Colors.white;
      final labelText =
          'Kimden: $_displayName${widget.labelSuffix.isEmpty ? '' : ' ${widget.labelSuffix.trim()}'}';
      final labelStyle = AppTypography.postAttribution.copyWith(
        color: widget.textColor,
        fontSize: widget.fontSize,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Kendi ID'si ise tıklanabilir olmasın
          final currentUserID = CurrentUserService.instance.effectiveUserId;
          if (effectiveUserID != currentUserID) {
            Get.to(() => SocialProfile(userID: effectiveUserID));
          }
        },
        child: useBackdrop
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        labelText,
                        style: labelStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Container(
                  color: Colors.transparent,
                  child: Text(
                    labelText,
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
      );
    }

    return const SizedBox.shrink();
  }
}
