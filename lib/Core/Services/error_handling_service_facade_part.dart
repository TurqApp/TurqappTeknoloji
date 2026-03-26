part of 'error_handling_service.dart';

ErrorHandlingService ensureErrorHandlingService() {
  final existing = maybeFindErrorHandlingService();
  if (existing != null) return existing;
  return Get.put(ErrorHandlingService());
}

ErrorHandlingService? maybeFindErrorHandlingService() {
  final isRegistered = Get.isRegistered<ErrorHandlingService>();
  if (!isRegistered) return null;
  return Get.find<ErrorHandlingService>();
}
