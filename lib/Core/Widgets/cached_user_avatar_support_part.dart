part of 'cached_user_avatar.dart';

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
