part of 'tutoring_repository.dart';

TutoringRepository? maybeFindTutoringRepository() =>
    Get.isRegistered<TutoringRepository>()
        ? Get.find<TutoringRepository>()
        : null;

TutoringRepository ensureTutoringRepository() =>
    maybeFindTutoringRepository() ??
    Get.put(TutoringRepository(), permanent: true);
