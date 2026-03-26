part of 'cikmis_sorular_repository_parts.dart';

class CikmisSorularRepository extends _CikmisSorularRepositoryBase {
  CikmisSorularRepository({
    FirebaseStorage? storage,
  }) : super(storage: storage ?? FirebaseStorage.instance);
}

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
