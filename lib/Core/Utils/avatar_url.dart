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
  final p = profile ?? const <String, dynamic>{};
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
