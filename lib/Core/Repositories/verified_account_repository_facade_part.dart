part of 'verified_account_repository.dart';

VerifiedAccountRepository? maybeFindVerifiedAccountRepository() {
  final isRegistered = Get.isRegistered<VerifiedAccountRepository>();
  if (!isRegistered) return null;
  return Get.find<VerifiedAccountRepository>();
}

VerifiedAccountRepository ensureVerifiedAccountRepository() {
  final existing = maybeFindVerifiedAccountRepository();
  if (existing != null) return existing;
  return Get.put(VerifiedAccountRepository(), permanent: true);
}
