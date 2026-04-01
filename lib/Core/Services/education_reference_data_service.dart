import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/dormitory_model.dart';
import 'package:turqappv2/Models/Education/high_school_model.dart';
import 'package:turqappv2/Models/Education/higher_education_model.dart';
import 'package:turqappv2/Models/middle_school_model.dart';

part 'education_reference_data_service_base_part.dart';
part 'education_reference_data_service_facade_part.dart';
part 'education_reference_data_service_data_part.dart';

List<String> _decodeCountryNames(String response) {
  final decoded = jsonDecode(response);
  if (decoded is! List) {
    return const <String>[];
  }
  final data = decoded;
  return data
      .whereType<Map>()
      .map((item) => item['name']?.toString().trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _decodeObjectEntries(String response) {
  final decoded = jsonDecode(response);
  if (decoded is! List) {
    return const <Map<String, dynamic>>[];
  }
  final data = decoded;
  return data
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}
