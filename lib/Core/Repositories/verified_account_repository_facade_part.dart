part of 'verified_account_repository.dart';

VerifiedAccountRepository? maybeFindVerifiedAccountRepository() =>
    Get.isRegistered<VerifiedAccountRepository>()
        ? Get.find<VerifiedAccountRepository>()
        : null;

VerifiedAccountRepository ensureVerifiedAccountRepository() =>
    maybeFindVerifiedAccountRepository() ??
    Get.put(VerifiedAccountRepository(), permanent: true);
