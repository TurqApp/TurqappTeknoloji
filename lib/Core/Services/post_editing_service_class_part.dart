part of 'post_editing_service.dart';

class PostEditingService extends GetxController {
  static PostEditingService? maybeFind() {
    final isRegistered = Get.isRegistered<PostEditingService>();
    if (!isRegistered) return null;
    return Get.find<PostEditingService>();
  }

  static PostEditingService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PostEditingService());
  }

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
