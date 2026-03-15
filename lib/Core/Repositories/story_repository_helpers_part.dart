part of 'story_repository.dart';

extension StoryRepositoryHelpersPart on StoryRepository {
  String _deletedStoriesCacheKey(String uid) => 'deleted_stories_cache_v1_$uid';

  String _resolveStoryNickname(Map<String, dynamic> data) {
    final nickname = (data['nickname'] ?? '').toString().trim();
    final username = (data['username'] ?? '').toString().trim();
    final usernameLower = (data['usernameLower'] ?? '').toString().trim();
    final hasSpace = nickname.contains(RegExp(r'\s'));
    if (nickname.isNotEmpty && !hasSpace) return nickname;
    if (username.isNotEmpty) return username;
    if (usernameLower.isNotEmpty) return usernameLower;
    return '';
  }

  String _resolveAvatar(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    return resolveAvatarUrl(data, profile: profile);
  }

  Map<String, dynamic> _fallbackUserData(
    String userId,
    CurrentUserService current,
  ) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null && myUid == userId) {
      final full = current.fullName.trim();
      final parts = full.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
      final first = parts.isNotEmpty ? parts.first : '';
      final last = parts.length > 1 ? parts.skip(1).join(' ') : '';
      return <String, dynamic>{
        'nickname': current.nickname,
        'firstName': first,
        'lastName': last,
        'avatarUrl': current.avatarUrl,
        'isPrivate': false,
      };
    }
    return const <String, dynamic>{
      'nickname': 'kullanici',
      'firstName': '',
      'lastName': '',
      'avatarUrl': '',
      'isPrivate': false,
    };
  }

  Future<Map<String, Map<String, dynamic>>> _loadMissingProfilesFromUsers(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return <String, Map<String, dynamic>>{};
    return _userRepository.getUsersRaw(userIds, preferCache: true);
  }
}
