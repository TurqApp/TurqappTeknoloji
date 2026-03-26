part of 'optics_and_books_published_controller.dart';

class OpticsAndBooksPublishedController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _OpticsAndBooksPublishedControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOpticsAndBooksPublishedInit(this);
  }
}
