part of 'optical_form_repository.dart';

OpticalFormRepository? maybeFindOpticalFormRepository() {
  final isRegistered = Get.isRegistered<OpticalFormRepository>();
  if (!isRegistered) return null;
  return Get.find<OpticalFormRepository>();
}

OpticalFormRepository ensureOpticalFormRepository() {
  final existing = maybeFindOpticalFormRepository();
  if (existing != null) return existing;
  return Get.put(OpticalFormRepository(), permanent: true);
}
