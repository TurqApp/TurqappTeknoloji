part of 'cikmis_sorular_controller.dart';

extension CikmisSorularControllerFacadePart on CikmisSorularController {
  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  void requestScrollReset() => _requestScrollReset();
}
