import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/dormitory_model.dart';
import 'package:turqappv2/Models/Education/high_school_model.dart';
import 'package:turqappv2/Models/Education/higher_education_model.dart';
import 'package:turqappv2/Models/middle_school_model.dart';

part 'education_reference_data_service_data_part.dart';

List<String> _decodeCountryNames(String response) {
  final data = jsonDecode(response) as List<dynamic>;
  return data
      .map((item) => (item as Map<String, dynamic>)['name'] as String)
      .toList(growable: false);
}

List<Map<String, dynamic>> _decodeObjectEntries(String response) {
  final data = jsonDecode(response) as List<dynamic>;
  return data
      .map(
        (item) => Map<String, dynamic>.from(item as Map),
      )
      .toList(growable: false);
}

class EducationReferenceDataService extends GetxService {
  static EducationReferenceDataService? maybeFind() {
    final isRegistered = Get.isRegistered<EducationReferenceDataService>();
    if (!isRegistered) return null;
    return Get.find<EducationReferenceDataService>();
  }

  static EducationReferenceDataService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(EducationReferenceDataService(), permanent: true);
  }

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
