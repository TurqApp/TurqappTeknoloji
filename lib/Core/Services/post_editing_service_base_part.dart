part of 'post_editing_service.dart';

abstract class _PostEditingServiceBase extends GetxController {
  final _PostEditingServiceState _state = _PostEditingServiceState();

  @override
  void onInit() {
    super.onInit();
    (this as PostEditingService)._startSuggestionGeneration();
  }
}
