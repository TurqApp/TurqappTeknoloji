part of 'search_deneme_controller.dart';

extension SearchDenemeControllerLifecyclePart on SearchDenemeController {
  void _scheduleFocusRequestImpl() {
    Future.delayed(const Duration(milliseconds: 100), () {
      focusNode.requestFocus();
    });
  }

  void _disposeFocusResourcesImpl() {
    searchController.dispose();
    focusNode.dispose();
  }
}
