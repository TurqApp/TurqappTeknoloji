import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/cities_model.dart';

part 'city_directory_service_fields_part.dart';
part 'city_directory_service_facade_part.dart';

List<Map<String, dynamic>> _decodeCityDirectory(String response) {
  final List<dynamic> data = jsonDecode(response) as List<dynamic>;
  return data
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}

class CityDirectoryService extends GetxService {
  final _state = _CityDirectoryServiceState();
}
