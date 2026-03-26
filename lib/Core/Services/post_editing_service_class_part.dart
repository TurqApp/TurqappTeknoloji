part of 'post_editing_service.dart';

class PostEditingService extends GetxController {
  final _PostEditingServiceState _state = _PostEditingServiceState();

  static const int _maxUndoActions = 50;
  static const List<String> _commonHashtags = [
    '#fotograf',
    '#video',
    '#muzik',
    '#sanat',
    '#seyahat',
    '#yemek',
    '#spor',
    '#teknoloji',
    '#kitap',
    '#film',
    '#doga',
    '#arkadas'
  ];

  @override
  void onInit() {
    super.onInit();
    _startSuggestionGeneration();
  }
}
