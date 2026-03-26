part of 'post_sharers_controller.dart';

PostSharersController ensurePostSharersController({
  required String postID,
  String? tag,
  bool permanent = false,
}) =>
    _ensurePostSharersController(
      postID: postID,
      tag: tag,
      permanent: permanent,
    );

PostSharersController? maybeFindPostSharersController({String? tag}) =>
    _maybeFindPostSharersController(tag: tag);
