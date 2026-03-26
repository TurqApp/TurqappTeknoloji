part of 'saved_optical_forms_controller_library.dart';

class _SavedOpticalFormsControllerState {
  final bookletRepository = ensureBookletRepository();
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;
  final userSubcollectionRepository = ensureUserSubcollectionRepository();
}

extension SavedOpticalFormsControllerFieldsPart on SavedOpticalFormsController {
  static final Expando<_SavedOpticalFormsControllerState> _stateExpando =
      Expando<_SavedOpticalFormsControllerState>(
    'saved_optical_forms_controller_state',
  );

  _SavedOpticalFormsControllerState get _state =>
      _stateExpando[this] ??= _SavedOpticalFormsControllerState();

  BookletRepository get _bookletRepository => _state.bookletRepository;
  RxList<BookletModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
}
