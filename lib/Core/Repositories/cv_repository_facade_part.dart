part of 'cv_repository.dart';

CvRepository? maybeFindCvRepository() =>
    Get.isRegistered<CvRepository>() ? Get.find<CvRepository>() : null;

CvRepository ensureCvRepository() =>
    maybeFindCvRepository() ?? Get.put(CvRepository(), permanent: true);
