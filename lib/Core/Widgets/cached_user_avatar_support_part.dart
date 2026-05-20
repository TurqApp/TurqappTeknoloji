part of 'cached_user_avatar.dart';

String resolveCachedUserAvatarBootstrapUrl({
  String? directImageUrl,
  required String userId,
  required String currentUserId,
  required String currentAvatarUrl,
  required String currentStreamAvatarUrl,
  String? cachedProfileAvatarUrl,
  String? cachedSummaryAvatarUrl,
}) {
  final candidates = <String>[
    directImageUrl ?? '',
  ];

  final normalizedUserId = userId.trim();
  if (normalizedUserId.isNotEmpty && normalizedUserId == currentUserId.trim()) {
    candidates
      ..add(currentAvatarUrl)
      ..add(currentStreamAvatarUrl);
  }

  candidates
    ..add(cachedProfileAvatarUrl ?? '')
    ..add(cachedSummaryAvatarUrl ?? '');

  return chooseFreshestCachedUserAvatarUrl(candidates);
}

String chooseFreshestCachedUserAvatarUrl(Iterable<String?> urls) {
  var selected = '';
  var selectedVersion = 0;
  for (final raw in urls) {
    final candidate = (raw ?? '').trim();
    if (candidate.isEmpty || isDefaultAvatarUrl(candidate)) continue;
    final candidateVersion = cachedUserAvatarUrlVersion(candidate);
    if (selected.isEmpty ||
        (candidateVersion > 0 && candidateVersion > selectedVersion)) {
      selected = candidate;
      selectedVersion = candidateVersion;
    }
  }
  return selected;
}

int cachedUserAvatarUrlVersion(String url) {
  final normalized = url.trim();
  if (normalized.isEmpty) return 0;
  final avatarMatch =
      RegExp(r'_(\d{10,})_avatarUrl(?:_|\.|$)').firstMatch(normalized);
  final genericMatch =
      avatarMatch ?? RegExp(r'_(\d{10,})(?:_|\.|$)').firstMatch(normalized);
  if (genericMatch == null) return 0;
  return int.tryParse(genericMatch.group(1) ?? '') ?? 0;
}

bool shouldReplaceCachedUserAvatarUrl({
  required String currentUrl,
  required String nextUrl,
}) {
  final current = currentUrl.trim();
  final next = nextUrl.trim();
  if (next.isEmpty || isDefaultAvatarUrl(next)) return false;
  if (current.isEmpty || isDefaultAvatarUrl(current)) return true;
  if (current == next) return false;

  final currentVersion = cachedUserAvatarUrlVersion(current);
  final nextVersion = cachedUserAvatarUrlVersion(next);
  if (currentVersion > 0 && nextVersion > 0) {
    return nextVersion >= currentVersion;
  }
  return true;
}

bool shouldDeferCachedUserAvatarPlaceholder({
  required bool bootstrapSettled,
  required bool bootstrapInFlight,
  required String resolvedFilePath,
  required String resolvedUrl,
  String? directImageUrl,
}) {
  if (bootstrapSettled || !bootstrapInFlight) return false;
  if (resolvedFilePath.trim().isNotEmpty || resolvedUrl.trim().isNotEmpty) {
    return true;
  }
  return (directImageUrl ?? '').trim().isNotEmpty;
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
    final useIconStyle = padding != null || iconColor != null;
    if (useIconStyle) {
      final effectiveBackgroundColor =
          backgroundColor ?? const Color(0xFFEDF2F7);
      final effectiveIconColor = iconColor ?? const Color(0xFF88A8C3);
      return CircleAvatar(
        radius: radius,
        backgroundColor: effectiveBackgroundColor,
        child: Padding(
          padding: padding ?? EdgeInsets.all(radius * 0.3),
          child: SvgPicture.asset(
            kDefaultAvatarAsset,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              effectiveIconColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          kDefaultAvatarAsset,
          fit: BoxFit.cover,
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

    if (userId != null && userId == userService.effectiveUserId) {
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
                        user?.nickname ?? 'common.user'.tr,
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
            nickname ?? 'common.user'.tr,
            style: nameStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
