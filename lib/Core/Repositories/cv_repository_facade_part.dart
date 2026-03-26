part of 'cv_repository.dart';

CvRepository? maybeFindCvRepository() {
  final isRegistered = Get.isRegistered<CvRepository>();
  if (!isRegistered) return null;
  return Get.find<CvRepository>();
}

CvRepository ensureCvRepository() {
  final existing = maybeFindCvRepository();
  if (existing != null) return existing;
  return Get.put(CvRepository(), permanent: true);
}
