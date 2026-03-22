import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Models/current_user_model.dart';

part 'user_repository_profile_part.dart';
part 'user_repository_query_part.dart';

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
    return UserSummary(
      userID: uid,
      displayName: (raw['displayName'] ?? '').toString().trim(),
      nickname: (raw['nickname'] ?? '').toString().trim(),
      username: (raw['username'] ?? '').toString().trim(),
      avatarUrl: resolveAvatarUrl(raw),
      bio: (raw['bio'] ?? '').toString(),
      rozet: (raw['rozet'] ?? '').toString().trim(),
      token: (raw['token'] ?? '').toString().trim(),
      followerCount: _toInt(raw['followerCount'] ?? raw['followersCount']),
      followingCount: _toInt(raw['followingCount']),
      postCount: _toInt(raw['postCount']),
      isPrivate: raw['isPrivate'] == true,
      isDeleted: raw['isDeleted'] == true,
      isApproved: raw['isApproved'] == true,
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
}

class UserRepository extends GetxService {
  final Map<String, _TimedUserLookup<bool>> _existsCache =
      <String, _TimedUserLookup<bool>>{};
  final Map<String, _TimedUserLookup<Map<String, dynamic>?>> _queryCache =
      <String, _TimedUserLookup<Map<String, dynamic>?>>{};

  static UserRepository? maybeFind() {
    final isRegistered = Get.isRegistered<UserRepository>();
    if (!isRegistered) return null;
    return Get.find<UserRepository>();
  }

  static UserRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserRepository(), permanent: true);
  }

  UserProfileCacheService get _cache {
    return UserProfileCacheService.ensure();
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
