import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/dormitory_model.dart';
import 'package:turqappv2/Models/Education/high_school_model.dart';
import 'package:turqappv2/Models/Education/higher_education_model.dart';
import 'package:turqappv2/Models/middle_school_model.dart';

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
  static EducationReferenceDataService get instance =>
      Get.find<EducationReferenceDataService>();

  static EducationReferenceDataService ensure() {
    if (Get.isRegistered<EducationReferenceDataService>()) {
      return Get.find<EducationReferenceDataService>();
    }
    return Get.put(EducationReferenceDataService(), permanent: true);
  }

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

  Future<List<String>> getCountries() async {
    final cached = _countries;
    if (cached != null) {
      return List<String>.from(cached);
    }
    final future = _countriesFuture ??= _loadCountries();
    final resolved = await future;
    _countries = resolved;
    _countriesFuture = null;
    return List<String>.from(resolved);
  }

  Future<List<MiddleSchoolModel>> getMiddleSchools() async {
    final entries = await getMiddleSchoolEntries();
    return entries
        .map((entry) => MiddleSchoolModel.fromJson(entry))
        .toList(growable: false);
  }

  Future<List<HighSchoolModel>> getHighSchools() async {
    final entries = await getHighSchoolEntries();
    return entries
        .map((entry) => HighSchoolModel.fromJson(entry))
        .toList(growable: false);
  }

  Future<List<HigherEducationModel>> getHigherEducations() async {
    final entries = await getHigherEducationEntries();
    return entries
        .map((entry) => HigherEducationModel.fromJson(entry))
        .toList(growable: false);
  }

  Future<List<DormitoryModel>> getDormitories() async {
    final entries = await getDormitoryEntries();
    return entries
        .map((entry) => DormitoryModel.fromJson(entry))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getMiddleSchoolEntries() async {
    final entries = await _resolveEntries(
      cached: _middleSchoolEntries,
      future: _middleSchoolEntriesFuture,
      assetPath: 'assets/data/MiddleSchool.json',
      assignCached: (value) => _middleSchoolEntries = value,
      clearFuture: () => _middleSchoolEntriesFuture = null,
      setFuture: (value) => _middleSchoolEntriesFuture = value,
    );
    return _cloneEntries(entries);
  }

  Future<List<Map<String, dynamic>>> getHighSchoolEntries() async {
    final entries = await _resolveEntries(
      cached: _highSchoolEntries,
      future: _highSchoolEntriesFuture,
      assetPath: 'assets/data/HighSchool.json',
      assignCached: (value) => _highSchoolEntries = value,
      clearFuture: () => _highSchoolEntriesFuture = null,
      setFuture: (value) => _highSchoolEntriesFuture = value,
    );
    return _cloneEntries(entries);
  }

  Future<List<Map<String, dynamic>>> getHigherEducationEntries() async {
    final entries = await _resolveEntries(
      cached: _higherEducationEntries,
      future: _higherEducationEntriesFuture,
      assetPath: 'assets/data/HigherEducation.json',
      assignCached: (value) => _higherEducationEntries = value,
      clearFuture: () => _higherEducationEntriesFuture = null,
      setFuture: (value) => _higherEducationEntriesFuture = value,
    );
    return _cloneEntries(entries);
  }

  Future<List<Map<String, dynamic>>> getDormitoryEntries() async {
    final entries = await _resolveEntries(
      cached: _dormitoryEntries,
      future: _dormitoryEntriesFuture,
      assetPath: 'assets/data/Dormitory.json',
      assignCached: (value) => _dormitoryEntries = value,
      clearFuture: () => _dormitoryEntriesFuture = null,
      setFuture: (value) => _dormitoryEntriesFuture = value,
    );
    return _cloneEntries(entries);
  }

  Future<List<String>> _loadCountries() async {
    final response = await rootBundle.loadString('assets/data/Countries.json');
    return compute(_decodeCountryNames, response);
  }

  Future<List<Map<String, dynamic>>> _resolveEntries({
    required List<Map<String, dynamic>>? cached,
    required Future<List<Map<String, dynamic>>>? future,
    required String assetPath,
    required void Function(List<Map<String, dynamic>> value) assignCached,
    required void Function() clearFuture,
    required void Function(Future<List<Map<String, dynamic>>> value) setFuture,
  }) async {
    if (cached != null) {
      return cached;
    }
    final inFlight = future ?? _loadEntries(assetPath);
    if (future == null) {
      setFuture(inFlight);
    }
    final resolved = await inFlight;
    assignCached(resolved);
    clearFuture();
    return resolved;
  }

  Future<List<Map<String, dynamic>>> _loadEntries(String assetPath) async {
    final response = await rootBundle.loadString(assetPath);
    return compute(_decodeObjectEntries, response);
  }

  List<Map<String, dynamic>> _cloneEntries(List<Map<String, dynamic>> entries) {
    return entries
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
}
