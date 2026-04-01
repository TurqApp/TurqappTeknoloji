part of 'education_reference_data_service.dart';

EducationReferenceDataService? maybeFindEducationReferenceDataService() =>
    Get.isRegistered<EducationReferenceDataService>()
        ? Get.find<EducationReferenceDataService>()
        : null;

EducationReferenceDataService ensureEducationReferenceDataService() =>
    maybeFindEducationReferenceDataService() ??
    Get.put(EducationReferenceDataService(), permanent: true);
