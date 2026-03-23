part of 'saved_posts_controller.dart';

extension SavedPostsControllerSortingPart on SavedPostsController {
  Future<void> _applySavedPosts(List<PostsModel> posts) async {
    final nextAgendas = <PostsModel>[];
    final nextPostsOnly = <PostsModel>[];
    final nextSeries = <PostsModel>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    final rootIdsInOrder = <String>[];
    final rootsById = <String, PostsModel>{};
    final singleIds = <String>{};
    final agendaIds = <String>{};

    for (final post in posts) {
      if (post.deletedPost == true) continue;
      if (post.timeStamp > now) continue;

      final isSeries = post.floodCount.toInt() > 1;
      if (isSeries) {
        final rootId = post.flood == true && post.mainFlood.trim().isNotEmpty
            ? post.mainFlood.trim()
            : post.docID;
        if (!rootIdsInOrder.contains(rootId)) {
          rootIdsInOrder.add(rootId);
        }
        if (rootId == post.docID) {
          rootsById[rootId] = post;
        }
        continue;
      }

      if (singleIds.add(post.docID)) {
        nextPostsOnly.add(post);
      }
    }

    final missingRootIds = rootIdsInOrder
        .where((rootId) => !rootsById.containsKey(rootId))
        .toList(growable: false);
    if (missingRootIds.isNotEmpty) {
      final fetchedRoots = await _postRepository.fetchPostsByIds(
        missingRootIds,
        preferCache: true,
      );
      rootsById.addAll(fetchedRoots);
    }

    for (final rootId in rootIdsInOrder) {
      final root = rootsById[rootId];
      if (root == null) continue;
      if (root.deletedPost == true || root.timeStamp > now) continue;
      nextSeries.add(root);
    }

    for (final post in posts) {
      if (post.deletedPost == true || post.timeStamp > now) continue;
      if (post.floodCount.toInt() > 1) continue;
      if (agendaIds.add(post.docID)) {
        nextAgendas.add(post);
      }
    }
    for (final post in nextSeries) {
      if (agendaIds.add(post.docID)) {
        nextAgendas.add(post);
      }
    }

    savedAgendas.assignAll(nextAgendas);
    savedPostsOnly.assignAll(nextPostsOnly);
    savedSeries.assignAll(nextSeries);
  }
}
