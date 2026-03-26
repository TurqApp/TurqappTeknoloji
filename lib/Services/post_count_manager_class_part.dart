part of 'post_count_manager.dart';

class PostCountManager extends GetxController {
  static PostCountManager? _instance;

  static PostCountManager? maybeFind() => _maybeFindPostCountManager();

  static PostCountManager ensure() => _ensurePostCountManager();

  static PostCountManager get instance => _postCountManagerInstance();

  final _state = _PostCountManagerState();
}
