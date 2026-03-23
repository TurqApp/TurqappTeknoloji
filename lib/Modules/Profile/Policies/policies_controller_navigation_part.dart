part of 'policies_controller.dart';

extension _PoliciesControllerNavigationPart on PoliciesController {
  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
