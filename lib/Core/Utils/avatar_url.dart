const String kDefaultAvatarUrl =
    'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';

String resolveAvatarUrl(
  Map<String, dynamic> data, {
  Map<String, dynamic>? profile,
}) {
  final p = profile ?? const <String, dynamic>{};
  final raw = (data['avatarUrl'] ?? p['avatarUrl'] ?? '')
      .toString()
      .trim();
  return raw.isEmpty ? kDefaultAvatarUrl : raw;
}
