part of 'app_language_service.dart';

AppLanguageService ensureAppLanguageService({bool permanent = true}) {
  final existing = maybeFindAppLanguageService();
  if (existing != null) return existing;
  return Get.put(AppLanguageService(), permanent: permanent);
}

AppLanguageService? maybeFindAppLanguageService() {
  final isRegistered = Get.isRegistered<AppLanguageService>();
  if (!isRegistered) return null;
  return Get.find<AppLanguageService>();
}

Future<AppLanguageService> ensureInitializedAppLanguageService() async {
  final existing = maybeFindAppLanguageService();
  if (existing != null) return existing;
  final service = await AppLanguageService().init();
  return Get.put(service, permanent: true);
}
