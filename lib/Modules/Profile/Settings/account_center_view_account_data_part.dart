part of 'account_center_view.dart';

extension AccountCenterViewAccountDataPart on StoredAccount {
  String get accountCenterNormalizedUsername => username.trim();

  String get accountCenterNormalizedDisplayName => displayName.trim();

  String get accountCenterPrimaryLabel =>
      accountCenterNormalizedUsername.isNotEmpty ? username : displayName;

  bool get hasDistinctAccountCenterDisplayName =>
      accountCenterNormalizedDisplayName.isNotEmpty &&
      accountCenterNormalizedDisplayName != accountCenterNormalizedUsername;

  String get accountCenterAvatarFallbackInitial =>
      accountCenterNormalizedDisplayName.isNotEmpty
          ? accountCenterNormalizedDisplayName[0].toUpperCase()
          : '@';
}
