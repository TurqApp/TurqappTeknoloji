part of 'social_media_links_repository.dart';

extension SocialMediaLinksRepositoryActionPart on SocialMediaLinksRepository {
  Future<void> _saveLinkImpl(
    String uid, {
    required SocialMediaModel model,
  }) async {
    if (uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('SosyalMedyaLinkleri')
        .doc(model.docID)
        .set({
      'title': model.title,
      'url': model.url,
      'sira': model.sira,
      'logo': model.logo,
    }, SetOptions(merge: true));

    final current = await getLinks(uid, preferCache: true, forceRefresh: false);
    final next = List<SocialMediaModel>.from(current)
      ..removeWhere((e) => e.docID == model.docID)
      ..add(model)
      ..sort((a, b) => a.sira.compareTo(b.sira));
    await setLinks(uid, next);
  }

  Future<void> _deleteLinkImpl(String uid, String docId) async {
    if (uid.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('SosyalMedyaLinkleri')
        .doc(docId)
        .delete();

    final current = await getLinks(uid, preferCache: true, forceRefresh: false);
    final next = current.where((e) => e.docID != docId).toList(growable: false);
    await setLinks(uid, next);
  }

  Future<void> _reorderLinksImpl(
    String uid,
    List<SocialMediaModel> items,
  ) async {
    if (uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final normalized = <SocialMediaModel>[];
    for (var i = 0; i < items.length; i++) {
      final model = items[i];
      batch.update(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('SosyalMedyaLinkleri')
            .doc(model.docID),
        {'sira': i},
      );
      normalized.add(
        SocialMediaModel(
          docID: model.docID,
          title: model.title,
          url: model.url,
          sira: i,
          logo: model.logo,
        ),
      );
    }
    await batch.commit();
    await setLinks(uid, normalized);
  }
}
