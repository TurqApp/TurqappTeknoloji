part of 'cikmis_sorular_repository_library.dart';

CikmisSorularRepository? maybeFindCikmisSorularRepository() {
  final isRegistered = Get.isRegistered<CikmisSorularRepository>();
  if (!isRegistered) return null;
  return Get.find<CikmisSorularRepository>();
}

CikmisSorularRepository ensureCikmisSorularRepository() {
  final existing = maybeFindCikmisSorularRepository();
  if (existing != null) return existing;
  return Get.put(CikmisSorularRepository(), permanent: true);
}
