part of 'tag_posts_controller.dart';

TagPostsController ensureTagPostsController({required String tag}) =>
    _ensureTagPostsController(tag: tag);

TagPostsController? maybeFindTagPostsController({String? tag}) =>
    _maybeFindTagPostsController(tag: tag);
