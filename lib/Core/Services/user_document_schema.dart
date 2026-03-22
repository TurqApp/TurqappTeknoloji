import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

const String _defaultProfileImageUrl = '';

Map<String, dynamic> buildInitialUserDocument({
  required String firstName,
  required String lastName,
  required String nickname,
  required String email,
  required String phoneNumber,
}) {
  final username = normalizeNicknameInput(nickname);
  final usernameLower = username;
  final normalizedEmail = normalizeEmailAddress(email);
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
    'moderationStrikeCount': 0,
    'moderationLevel': 0,
    'moderationRestrictedUntil': 0,
    'moderationPermanentBan': false,
    'moderationBanReason': '',
    'moderationUpdatedAt': 0,
    'singleDeviceSessionEnabled': false,
    'activeSessionDeviceKey': '',
    'activeSessionUpdatedAt': 0,
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
