part of 'my_booklet_results_controller.dart';

class _MyBookletResultsControllerState {
  final opticalFormSnapshotRepository = ensureOpticalFormSnapshotRepository();
  final userSubcollectionRepository = ensureUserSubcollectionRepository();
  final list = <BookletResultModel>[].obs;
  final optikSonuclari = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final isLoading = true.obs;
}

extension MyBookletResultsControllerFieldsPart on MyBookletResultsController {
  OpticalFormSnapshotRepository get _opticalFormSnapshotRepository =>
      _state.opticalFormSnapshotRepository;
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
  RxList<BookletResultModel> get list => _state.list;
  RxList<OpticalFormModel> get optikSonuclari => _state.optikSonuclari;
  RxInt get selection => _state.selection;
  RxBool get isLoading => _state.isLoading;
}
