part of 'booklet_repository.dart';

BookletRepository? maybeFindBookletRepository() {
  final isRegistered = Get.isRegistered<BookletRepository>();
  if (!isRegistered) return null;
  return Get.find<BookletRepository>();
}

BookletRepository ensureBookletRepository() {
  final existing = maybeFindBookletRepository();
  if (existing != null) return existing;
  return Get.put(BookletRepository(), permanent: true);
}
