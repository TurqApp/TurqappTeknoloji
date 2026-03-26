part of 'city_directory_service.dart';

extension CityDirectoryServiceFacadePart on CityDirectoryService {
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
      final response =
          await rootBundle.loadString(CityDirectoryService._assetPath);
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
