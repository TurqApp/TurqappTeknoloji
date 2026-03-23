part of 'profile_view.dart';

extension _ProfileViewArchivePart on _ProfileViewState {
  Future<void> arsivle(PostsModel model) async {
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update(
      {
        "arsiv": true,
      },
    );

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isVisible = (model.timeStamp <= nowMs) && !model.flood;
      if (isVisible) {
        final me = _myUserId;
        if (me.isNotEmpty) {
          await UserRepository.ensure().updateUserFields(
            me,
            {'counterOfPosts': FieldValue.increment(-1)},
            mergeIntoCache: false,
          );
        }
      }
    } catch (_) {}

    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].arsiv = true;
    final exploreController = ExploreController.maybeFind();

    final index3 = exploreController?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) {
      exploreController!.explorePosts[index3].arsiv = true;
    }

    final index4 = exploreController?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) {
      exploreController!.explorePhotos[index4].arsiv = true;
    }

    final index5 = exploreController?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) {
      exploreController!.exploreVideos[index5].arsiv = true;
    }

    final store8 = AgendaController.maybeFind();
    if (store8 != null) {
      final index8 = store8.agendaList.indexOf(model);
      if (index8 >= 0) store8.agendaList[index8].arsiv = true;
    }

    final store9 = ProfileController.ensure();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = true;

    final store10 = ProfileController.ensure();
    final index10 = store10.videos.indexOf(model);
    if (index10 >= 0) store10.videos[index10].arsiv = true;

    final store11 = ProfileController.ensure();
    final index11 = store11.photos.indexOf(model);
    if (index11 >= 0) store11.photos[index11].arsiv = true;

    controller.photos.refresh();
    controller.videos.refresh();
    controller.allPosts.refresh();
  }
}
