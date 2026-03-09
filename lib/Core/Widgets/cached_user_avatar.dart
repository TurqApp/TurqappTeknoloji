// 📁 lib/Core/Widgets/CachedUserAvatar.dart
// 🎯 Optimized user avatar with aggressive caching
// Uses CurrentUserService for current user, CachedNetworkImage for others

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Services/current_user_service.dart';

/// Cached user avatar with smart loading
///
/// **Features:**
/// - Current user: Instant from CurrentUserService (no network)
/// - Other users: CachedNetworkImage (disk cache)
/// - Automatic refresh on user updates
/// - Shimmer loading effect
///
/// **Usage:**
/// ```dart
/// CachedUserAvatar(
///   userId: 'user123',
///   radius: 40,
/// )
/// ```
class CachedUserAvatar extends StatelessWidget {
  static const String _defaultProfileImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';
  final String? userId;
  final double radius;
  final String? imageUrl; // Manual override
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
  Widget build(BuildContext context) {
    final userService = CurrentUserService.instance;

    // 1️⃣ Current user - use reactive service (instant!)
    if (userId != null && userId == userService.userId) {
      return StreamBuilder(
        stream: userService.userStream,
        initialData: userService.currentUser,
        builder: (context, snapshot) {
          final currentUserImage =
              (snapshot.data?.avatarUrl ?? _defaultProfileImageUrl).trim();
          return _buildAvatar(
            currentUserImage.isEmpty
                ? _defaultProfileImageUrl
                : currentUserImage,
          );
        },
      );
    }

    // 2️⃣ Manual URL provided
    if (imageUrl != null) {
      return _buildAvatar(imageUrl!);
    }

    // 3️⃣ Other user - need to fetch (handled by parent)
    return _buildAvatar('');
  }

  Widget _buildAvatar(String url) {
    final normalizedUrl = _normalizeUrl(url);
    if (normalizedUrl.isEmpty) {
      return _fallbackAvatar();
    }
    return _buildNetworkAvatar(normalizedUrl);
  }

  Widget _buildNetworkAvatar(
    String imageUrl, {
    bool attemptedDefault = false,
  }) {
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: backgroundColor ?? Colors.grey[300],
          ),
          errorWidget: (_, __, ___) {
            if (!attemptedDefault && imageUrl != _defaultProfileImageUrl) {
              return _buildNetworkAvatar(
                _defaultProfileImageUrl,
                attemptedDefault: true,
              );
            }
            return _fallbackAvatar();
          },
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: Icon(
        Icons.person,
        size: radius,
        color: Colors.grey[600],
      ),
    );
  }

  String _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return _defaultProfileImageUrl;
    return trimmed;
  }
}

/// Extended version with username/nickname display
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

    // Current user - reactive
    if (userId != null && userId == userService.userId) {
      return StreamBuilder(
        stream: userService.userStream,
        initialData: userService.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Row(
            children: [
              CachedUserAvatar(
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
                      Icon(
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

    // Other user - static
    return Row(
      children: [
        CachedUserAvatar(
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
