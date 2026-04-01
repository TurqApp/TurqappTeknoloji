part of 'tutoring_controller.dart';

class TutoringController extends _TutoringControllerBase {
  static const int _pageSize = ReadBudgetRegistry.tutoringHomeInitialLimit;

  bool get hasActiveSearch => _hasActiveTutoringSearch(this);
}
