import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/dormitory_model.dart';
import 'package:turqappv2/Models/Education/high_school_model.dart';
import 'package:turqappv2/Models/Education/higher_education_model.dart';
import 'package:turqappv2/Models/middle_school_model.dart';

part 'education_reference_data_service_class_part.dart';
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
