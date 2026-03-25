part of 'location_based_tutoring_controller.dart';

class _LocationBasedTutoringControllerState {
  final isLoading = true.obs;
  final tutoringList = <TutoringModel>[].obs;
}

extension LocationBasedTutoringControllerFieldsPart
    on LocationBasedTutoringController {
  RxBool get isLoading => _state.isLoading;
  RxList<TutoringModel> get tutoringList => _state.tutoringList;
}
