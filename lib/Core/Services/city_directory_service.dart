import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/cities_model.dart';

List<Map<String, dynamic>> _decodeCityDirectory(String response) {
  final List<dynamic> data = jsonDecode(response) as List<dynamic>;
  return data
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}

class CityDirectoryService extends GetxService {
  static const String _assetPath = 'assets/data/CityDistrict.json';

  List<CitiesModel>? _cachedCities;
  List<String>? _cachedSortedCities;
  Future<List<CitiesModel>>? _loadingFuture;

  static CityDirectoryService _ensureService() {
    if (Get.isRegistered<CityDirectoryService>()) {
      return Get.find<CityDirectoryService>();
    }
    return Get.put(CityDirectoryService(), permanent: true);
  }

  static CityDirectoryService ensure() {
    return _ensureService();
  }

  Future<List<CitiesModel>> getCitiesAndDistricts() {
    final cached = _cachedCities;
    if (cached != null) {
      return Future<List<CitiesModel>>.value(
        List<CitiesModel>.from(cached),
      );
    }
    return _loadingFuture ??= _loadCities();
  }

  Future<List<String>> getSortedCities({
    bool includeAllTurkey = false,
  }) async {
    final cached = _cachedSortedCities;
    if (cached != null) {
      return _copyCityNames(
        cached,
        includeAllTurkey: includeAllTurkey,
      );
    }

    final all = await getCitiesAndDistricts();
    final sorted = all.map((item) => item.il).toSet().toList(growable: false);
    final mutable = List<String>.from(sorted);
    sortTurkishStrings(mutable);
    _cachedSortedCities = List<String>.from(mutable);
    return _copyCityNames(
      _cachedSortedCities!,
      includeAllTurkey: includeAllTurkey,
    );
  }

  Future<List<CitiesModel>> _loadCities() async {
    try {
      final response = await rootBundle.loadString(_assetPath);
      final decoded = await compute(_decodeCityDirectory, response);
      final parsed = decoded.map(CitiesModel.fromJson).toList(growable: false);
      _cachedCities = List<CitiesModel>.from(parsed);
      return parsed;
    } finally {
      _loadingFuture = null;
    }
  }

  List<String> _copyCityNames(
    List<String> source, {
    required bool includeAllTurkey,
  }) {
    final items = List<String>.from(source);
    if (includeAllTurkey) {
      items.insert(0, 'pasaj.common.all_turkiye'.tr);
    }
    return items;
  }
}
