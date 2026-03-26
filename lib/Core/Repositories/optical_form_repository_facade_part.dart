part of 'optical_form_repository.dart';

OpticalFormRepository? maybeFindOpticalFormRepository() =>
    Get.isRegistered<OpticalFormRepository>()
        ? Get.find<OpticalFormRepository>()
        : null;

OpticalFormRepository ensureOpticalFormRepository() =>
    maybeFindOpticalFormRepository() ??
    Get.put(OpticalFormRepository(), permanent: true);
