part of 'error_handling_service_library.dart';

ErrorHandlingService ensureErrorHandlingService() =>
    maybeFindErrorHandlingService() ?? Get.put(ErrorHandlingService());

ErrorHandlingService? maybeFindErrorHandlingService() =>
    Get.isRegistered<ErrorHandlingService>()
        ? Get.find<ErrorHandlingService>()
        : null;
