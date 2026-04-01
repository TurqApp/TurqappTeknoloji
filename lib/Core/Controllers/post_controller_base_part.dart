part of 'post_controller.dart';

abstract class _PostControllerBase extends GetxController {
  late final PostInteractionService _interactionService;

  @override
  void onInit() {
    super.onInit();
    _interactionService = ensurePostInteractionService();
  }
}
