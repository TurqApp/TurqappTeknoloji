const String kDefaultAvatarUrl = '';
const String kLegacyDefaultAvatarUrl =
    'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';
const String kDefaultAvatarAsset = 'assets/icons/person.svg';

bool isDefaultAvatarUrl(String? raw) {
  final normalized = (raw ?? '').trim();
  return normalized.isEmpty || normalized == kLegacyDefaultAvatarUrl;
}

String resolveAvatarUrl(
  Map<String, dynamic> data, {
  Map<String, dynamic>? profile,
}) {
  final p = profile ?? const <String, dynamic>{};
  final raw = (data['avatarUrl'] ?? p['avatarUrl'] ?? '').toString().trim();
  return isDefaultAvatarUrl(raw) ? kDefaultAvatarUrl : raw;
}
