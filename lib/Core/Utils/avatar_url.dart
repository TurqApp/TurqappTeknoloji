const String kDefaultAvatarUrl = '';
const String kLegacyDefaultAvatarUrl =
    'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';
const String kDefaultAvatarAsset = 'assets/icons/default_profile_avatar.svg';

bool isDefaultAvatarUrl(String? raw) {
  final normalized = (raw ?? '').trim();
  return normalized.isEmpty || normalized == kLegacyDefaultAvatarUrl;
}

String resolveAvatarUrl(
  Map<String, dynamic> data, {
  Map<String, dynamic>? profile,
}) {
  Map<String, dynamic> nestedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, dynamic>{};
  }

  final nestedProfile = nestedMap(data['profile']);
  final nestedPublicProfile = nestedMap(data['publicProfile']);
  final p = <String, dynamic>{}
    ..addAll(nestedProfile)
    ..addAll(nestedPublicProfile)
    ..addAll(profile ?? const <String, dynamic>{});
  const keys = <String>[
    'avatarUrl',
    'profileImage',
    'profileImageUrl',
    'photoUrl',
    'imageUrl',
    'image',
  ];
  for (final key in keys) {
    final raw = (data[key] ?? p[key] ?? '').toString().trim();
    if (!isDefaultAvatarUrl(raw) && raw.isNotEmpty) {
      return raw;
    }
  }
  return kDefaultAvatarUrl;
}
