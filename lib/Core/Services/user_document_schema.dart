const String _defaultProfileImageUrl =
    'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';

Map<String, dynamic> buildInitialUserDocument({
  required String firstName,
  required String lastName,
  required String nickname,
  required String email,
  required String phoneNumber,
}) {
  final normalizedNickname = nickname.trim();
  final username = normalizedNickname.toLowerCase();
  final usernameLower = username;
  final normalizedEmail = email.trim().toLowerCase();
  final normalizedPhone = phoneNumber.trim();
  final normalizedFirstName = firstName.trim();
  final normalizedLastName = lastName.trim();
  final normalizedDisplayName = [normalizedFirstName, normalizedLastName]
      .where((e) => e.isNotEmpty)
      .join(' ');
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  return <String, dynamic>{
    'displayName': normalizedDisplayName,
    'username': username,
    'usernameLower': usernameLower,
    'nickname': username,
    'firstName': normalizedFirstName,
    'lastName': normalizedLastName,
    'rozet': '',
    'email': normalizedEmail,
    'phoneNumber': normalizedPhone,
    'avatarUrl': _defaultProfileImageUrl,
    'createdDate': nowMs,
    'updatedDate': nowMs,
    'deletedAt': null,
    'version': 3,
    'accountStatus': 'active',
    'isOnboarded': false,
    'locale': 'tr_TR',
    'timezone': 'Europe/Istanbul',
    'emailVerified': false,
    'bio': '',
    'meslekKategori': '',
    'isBanned': false,
    'isBot': false,
    'isDeleted': false,
    'isPrivate': false,
    'isApproved': false,
    'isAdvertiser': false,
    'counterOfFollowers': 0,
    'counterOfFollowings': 0,
    'counterOfPosts': 0,
  };
}

Map<String, Map<String, dynamic>> buildInitialUserSubdocuments({
  required Map<String, dynamic> userDoc,
}) {
  return <String, Map<String, dynamic>>{
    'settings/preferences': <String, dynamic>{
      'settings': '',
      'themeSettings': '',
      'viewSelection': 1,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    },
  };
}
