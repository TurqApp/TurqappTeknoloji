import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class CachedUserAvatar extends StatefulWidget {
  final String? userId;
  final double radius;
  final String? imageUrl;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedUserAvatar({
    super.key,
    this.userId,
    this.radius = 20,
    this.imageUrl,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedUserAvatar> createState() => _CachedUserAvatarState();
}

class _CachedUserAvatarState extends State<CachedUserAvatar> {
  String _resolvedUrl = '';
  bool _didBootstrap = false;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _normalizeUrl(widget.imageUrl);
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(covariant CachedUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextResolved = _normalizeUrl(widget.imageUrl);
    if (oldWidget.userId != widget.userId ||
        oldWidget.imageUrl != widget.imageUrl) {
      _resolvedUrl = nextResolved;
      _didBootstrap = false;
      unawaited(_bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    if (_didBootstrap) return;
    _didBootstrap = true;

    final uid = (widget.userId ?? '').trim();
    if (uid.isEmpty) return;

    final currentUser = CurrentUserService.instance;
    if (uid == currentUser.userId) {
      final currentAvatar = _normalizeUrl(currentUser.avatarUrl);
      if (currentAvatar.isNotEmpty &&
          currentAvatar != _resolvedUrl &&
          mounted) {
        setState(() {
          _resolvedUrl = currentAvatar;
        });
      }
      return;
    }

    if (!Get.isRegistered<UserProfileCacheService>()) return;
    final cache = Get.find<UserProfileCacheService>();

    try {
      final cached = await cache.getProfile(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final cachedUrl = _normalizeUrl(cached?['avatarUrl']?.toString());
      if (cachedUrl.isNotEmpty && cachedUrl != _resolvedUrl && mounted) {
        setState(() {
          _resolvedUrl = cachedUrl;
        });
      }
    } catch (_) {}

    if (_resolvedUrl.isNotEmpty) return;

    try {
      final fetched = await cache.getProfile(
        uid,
        preferCache: true,
        cacheOnly: false,
      );
      final fetchedUrl = _normalizeUrl(fetched?['avatarUrl']?.toString());
      if (fetchedUrl.isNotEmpty && fetchedUrl != _resolvedUrl && mounted) {
        setState(() {
          _resolvedUrl = fetchedUrl;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final userService = CurrentUserService.instance;
    final uid = (widget.userId ?? '').trim();

    if (uid.isNotEmpty && uid == userService.userId) {
      return StreamBuilder(
        stream: userService.userStream,
        initialData: userService.currentUser,
        builder: (context, snapshot) {
          final currentUserImage =
              _normalizeUrl((snapshot.data?.avatarUrl ?? '').trim());
          return _buildAvatar(currentUserImage);
        },
      );
    }

    return _buildAvatar(_resolvedUrl);
  }

  Widget _buildAvatar(String url) {
    if (url.isEmpty) {
      return widget.placeholder ??
          DefaultAvatar(
            radius: widget.radius,
            backgroundColor: widget.backgroundColor,
            iconColor: Colors.grey[600],
          );
    }
    return _buildNetworkAvatar(url);
  }

  Widget _buildNetworkAvatar(String imageUrl) {
    final size = widget.radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              widget.placeholder ??
              Container(color: widget.backgroundColor ?? Colors.grey[300]),
          errorWidget: (_, __, ___) =>
              widget.errorWidget ??
              DefaultAvatar(
                radius: widget.radius,
                backgroundColor: widget.backgroundColor,
                iconColor: Colors.grey[600],
              ),
        ),
      ),
    );
  }

  String _normalizeUrl(String? raw) {
    final trimmed = (raw ?? '').trim();
    return isDefaultAvatarUrl(trimmed) ? '' : trimmed;
  }
}

class DefaultAvatar extends StatelessWidget {
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const DefaultAvatar({
    super.key,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: Padding(
        padding: padding ?? EdgeInsets.all(radius * 0.3),
        child: SvgPicture.asset(
          kDefaultAvatarAsset,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            iconColor ?? Colors.grey[600]!,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class CachedUserAvatarWithName extends StatelessWidget {
  final String? userId;
  final String? imageUrl;
  final String? nickname;
  final double avatarRadius;
  final TextStyle? nameStyle;
  final bool showVerifiedBadge;

  const CachedUserAvatarWithName({
    super.key,
    this.userId,
    this.imageUrl,
    this.nickname,
    this.avatarRadius = 20,
    this.nameStyle,
    this.showVerifiedBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final userService = CurrentUserService.instance;

    if (userId != null && userId == userService.userId) {
      return StreamBuilder(
        stream: userService.userStream,
        initialData: userService.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Row(
            children: [
              CachedUserAvatar(
                userId: userId,
                imageUrl: user?.avatarUrl,
                radius: avatarRadius,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        user?.nickname ?? 'User',
                        style: nameStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showVerifiedBadge && (user?.isVerified ?? false)) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return Row(
      children: [
        CachedUserAvatar(
          userId: userId,
          imageUrl: imageUrl,
          radius: avatarRadius,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            nickname ?? 'User',
            style: nameStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
