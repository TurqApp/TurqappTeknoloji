part of 'liked_posts_controller.dart';

LikedPostControllers? maybeFindLikedPostControllers() {
  final isRegistered = Get.isRegistered<LikedPostControllers>();
  if (!isRegistered) return null;
  return Get.find<LikedPostControllers>();
}

LikedPostControllers ensureLikedPostControllers() {
  final existing = maybeFindLikedPostControllers();
  if (existing != null) return existing;
  return Get.put(LikedPostControllers());
}

extension LikedPostsControllerFacadePart on LikedPostControllers {
  List<PostsModel> get likedAll => all;

  List<PostsModel> get likedPostsOnly => all
      .where((post) => !LikedPostControllers.isSeriesPost(post))
      .toList(growable: false);

  List<PostsModel> get likedSeries =>
      all.where(LikedPostControllers.isSeriesPost).toList(growable: false);

  void goToPage(int index) =>
      _LikedPostsControllerNavigationPart(this).goToPage(index);

  GlobalKey getPostKey(String docId) =>
      _LikedPostsControllerNavigationPart(this).getPostKey(docId);

  String agendaInstanceTag(String docId) =>
      _LikedPostsControllerNavigationPart(this).agendaInstanceTag(docId);

  void disposeAgendaContentController(String docId) =>
      _LikedPostsControllerNavigationPart(this)
          .disposeAgendaContentController(docId);

  int resolveResumeCenteredIndex() =>
      _LikedPostsControllerNavigationPart(this).resolveResumeCenteredIndex();

  void resumeCenteredPost() =>
      _LikedPostsControllerNavigationPart(this).resumeCenteredPost();

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) =>
      _LikedPostsControllerNavigationPart(this).capturePendingCenteredEntry(
        preferredIndex: preferredIndex,
        model: model,
      );
}
