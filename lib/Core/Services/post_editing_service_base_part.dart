part of 'post_editing_service.dart';

class PostEditingService extends GetxController {
  final _PostEditingServiceState _state = _PostEditingServiceState();

  @override
  void onInit() {
    super.onInit();
    _startSuggestionGeneration();
  }
}
