part of 'education_reference_data_service.dart';

class EducationReferenceDataService extends GetxService {
  static EducationReferenceDataService? maybeFind() =>
      Get.isRegistered<EducationReferenceDataService>()
          ? Get.find<EducationReferenceDataService>()
          : null;

  static EducationReferenceDataService ensure() =>
      maybeFind() ?? Get.put(EducationReferenceDataService(), permanent: true);

  static EducationReferenceDataService get instance => ensure();

  List<String>? _countries;
  Future<List<String>>? _countriesFuture;
  List<Map<String, dynamic>>? _middleSchoolEntries;
  Future<List<Map<String, dynamic>>>? _middleSchoolEntriesFuture;
  List<Map<String, dynamic>>? _highSchoolEntries;
  Future<List<Map<String, dynamic>>>? _highSchoolEntriesFuture;
  List<Map<String, dynamic>>? _higherEducationEntries;
  Future<List<Map<String, dynamic>>>? _higherEducationEntriesFuture;
  List<Map<String, dynamic>>? _dormitoryEntries;
  Future<List<Map<String, dynamic>>>? _dormitoryEntriesFuture;
}
