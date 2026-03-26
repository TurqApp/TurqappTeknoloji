part of 'tutoring_search_controller.dart';

class _TutoringSearchControllerState {
  final TutoringSnapshotRepository tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final TextEditingController searchController = TextEditingController();
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxList<TutoringModel> searchResults = <TutoringModel>[].obs;
  List<TutoringModel> initialTutorings = <TutoringModel>[];
}

extension TutoringSearchControllerFieldsPart on TutoringSearchController {
  TutoringSnapshotRepository get _tutoringSnapshotRepository =>
      _state.tutoringSnapshotRepository;
  TextEditingController get searchController => _state.searchController;
  RxBool get isLoading => _state.isLoading;
  RxString get searchQuery => _state.searchQuery;
  RxList<TutoringModel> get searchResults => _state.searchResults;
  List<TutoringModel> get _initialTutorings => _state.initialTutorings;
  set _initialTutorings(List<TutoringModel> value) =>
      _state.initialTutorings = value;
}
