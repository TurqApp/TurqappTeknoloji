part of 'verified_account_repository.dart';

class _CachedVerifiedAccountStatus {
  final bool exists;
  final DateTime cachedAt;

  const _CachedVerifiedAccountStatus({
    required this.exists,
    required this.cachedAt,
  });
}

class VerifiedAccountApplicationState {
  final bool exists;
  final String status;
  final String selected;
  final int badgeExpiresAt;
  final int renewalOpensAt;

  const VerifiedAccountApplicationState({
    required this.exists,
    required this.status,
    required this.selected,
    required this.badgeExpiresAt,
    required this.renewalOpensAt,
  });

  bool get isPending => status == 'pending' || status == 'reviewing';
  bool get canSubmitRenewal =>
      status == 'renewal_open' || status == 'expired' || status == 'rejected';
}
