part of 'education_reference_data_service.dart';

abstract class _EducationReferenceDataServiceBase extends GetxService {
  List<String>? _countries;
  Future<List<String>>? _countriesFuture;
  List<Map<String, dynamic>>? _middleSchoolEntries, _highSchoolEntries;
  Future<List<Map<String, dynamic>>>? _middleSchoolEntriesFuture,
      _highSchoolEntriesFuture;
  List<Map<String, dynamic>>? _higherEducationEntries, _dormitoryEntries;
  Future<List<Map<String, dynamic>>>? _higherEducationEntriesFuture,
      _dormitoryEntriesFuture;
}

class EducationReferenceDataService
    extends _EducationReferenceDataServiceBase {}
