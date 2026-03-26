part of 'education_reference_data_service.dart';

abstract class _EducationReferenceDataServiceBase extends GetxService {
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
