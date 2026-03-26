part of 'city_directory_service.dart';

class _CityDirectoryServiceState {
  List<CitiesModel>? cachedCities;
  List<String>? cachedSortedCities;
  Future<List<CitiesModel>>? loadingFuture;
}

extension CityDirectoryServiceFieldsPart on CityDirectoryService {
  List<CitiesModel>? get _cachedCities => _state.cachedCities;
  set _cachedCities(List<CitiesModel>? value) => _state.cachedCities = value;

  List<String>? get _cachedSortedCities => _state.cachedSortedCities;
  set _cachedSortedCities(List<String>? value) =>
      _state.cachedSortedCities = value;

  Future<List<CitiesModel>>? get _loadingFuture => _state.loadingFuture;
  set _loadingFuture(Future<List<CitiesModel>>? value) =>
      _state.loadingFuture = value;
}
