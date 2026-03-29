part of 'user_repository.dart';

class UserSummary {
  final String userID;
  final String displayName;
  final String nickname;
  final String username;
  final String avatarUrl;
  final String bio;
  final String rozet;
  final String token;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isPrivate;
  final bool isDeleted;
  final bool isApproved;

  const UserSummary({
    required this.userID,
    required this.displayName,
    required this.nickname,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.rozet,
    required this.token,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.isPrivate,
    required this.isDeleted,
    required this.isApproved,
  });

  factory UserSummary.fromMap(String uid, Map<String, dynamic> raw) {
    final profile = (raw['profile'] is Map)
        ? Map<String, dynamic>.from(raw['profile'] as Map)
        : const <String, dynamic>{};
    final publicProfile = (raw['publicProfile'] is Map)
        ? Map<String, dynamic>.from(raw['publicProfile'] as Map)
        : const <String, dynamic>{};
    final scoped = <String, dynamic>{}
      ..addAll(profile)
      ..addAll(publicProfile);

    return UserSummary(
      userID: uid,
      displayName:
          (raw['displayName'] ?? scoped['displayName'] ?? '').toString().trim(),
      nickname: (raw['nickname'] ?? scoped['nickname'] ?? '').toString().trim(),
      username: (raw['username'] ?? scoped['username'] ?? '').toString().trim(),
      avatarUrl: resolveAvatarUrl(raw, profile: scoped),
      bio: (raw['bio'] ?? scoped['bio'] ?? '').toString(),
      rozet: (raw['rozet'] ??
              raw['badge'] ??
              scoped['rozet'] ??
              scoped['badge'] ??
              '')
          .toString()
          .trim(),
      token: (raw['token'] ?? scoped['token'] ?? '').toString().trim(),
      followerCount: _toInt(raw['followerCount'] ?? raw['followersCount']),
      followingCount: _toInt(raw['followingCount']),
      postCount: _toInt(raw['postCount']),
      isPrivate: _toBool(raw['isPrivate'] ?? scoped['isPrivate']),
      isDeleted: _toBool(raw['isDeleted'] ?? scoped['isDeleted']),
      isApproved: _toBool(raw['isApproved'] ?? scoped['isApproved']),
    );
  }

  factory UserSummary.fromCurrentUser(CurrentUserModel user) {
    final fullName = [user.firstName.trim(), user.lastName.trim()]
        .where((e) => e.isNotEmpty)
        .join(' ');
    return UserSummary(
      userID: user.userID,
      displayName: fullName.isNotEmpty ? fullName : user.nickname.trim(),
      nickname: user.nickname.trim(),
      username: user.nickname.trim(),
      avatarUrl: user.avatarUrl.trim(),
      bio: user.bio,
      rozet: user.rozet.trim(),
      token: user.token.trim(),
      followerCount: user.counterOfFollowers,
      followingCount: user.counterOfFollowings,
      postCount: user.counterOfPosts,
      isPrivate: user.gizliHesap,
      isDeleted: user.deletedAccount,
      isApproved: user.hesapOnayi,
    );
  }

  String get preferredName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (nickname.trim().isNotEmpty) return nickname.trim();
    return username.trim();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userID': userID,
      'displayName': displayName,
      'nickname': nickname,
      'username': username,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'rozet': rozet,
      'token': token,
      'followerCount': followerCount,
      'followersCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'isPrivate': isPrivate,
      'isDeleted': isDeleted,
      'isApproved': isApproved,
    };
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic raw, {bool fallback = false}) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.isEmpty) return fallback;
      switch (normalized) {
        case 'true':
        case '1':
        case 'yes':
        case 'y':
        case 'on':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'n':
        case 'off':
          return false;
      }
    }
    return fallback;
  }
}

class _TimedUserLookup<T> {
  const _TimedUserLookup({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
