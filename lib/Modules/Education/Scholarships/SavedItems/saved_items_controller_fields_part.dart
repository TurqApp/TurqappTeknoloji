part of 'saved_items_controller.dart';

extension SavedItemsControllerFieldsPart on SavedItemsController {
  RxBool get isLoading => _state.isLoading;
  RxList<Map<String, dynamic>> get likedScholarships =>
      _state.likedScholarships;
  RxList<Map<String, dynamic>> get bookmarkedScholarships =>
      _state.bookmarkedScholarships;
  RxInt get selectedTabIndex => _state.selectedTabIndex;
  PageController get pageController => _state.pageController;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  ScholarshipRepository get _scholarshipRepository =>
      _state.scholarshipRepository;
}
