part of 'personel_info_controller.dart';

PersonelInfoController ensurePersonelInfoController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindPersonelInfoController(tag: tag);
  if (existing != null) return existing;
  return Get.put(PersonelInfoController(), tag: tag, permanent: permanent);
}

PersonelInfoController? maybeFindPersonelInfoController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<PersonelInfoController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PersonelInfoController>(tag: tag);
}
