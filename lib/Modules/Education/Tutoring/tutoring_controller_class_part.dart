part of 'tutoring_controller.dart';

class TutoringController extends _TutoringControllerBase {
  static const int _pageSize = 30;

  bool get hasActiveSearch => _hasActiveTutoringSearch(this);
}
