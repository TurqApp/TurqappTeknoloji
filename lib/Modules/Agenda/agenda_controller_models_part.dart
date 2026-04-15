part of 'agenda_controller.dart';

enum FeedViewMode { forYou, following, city }

class _AgendaSourcePage {
  const _AgendaSourcePage(
    this.items,
    this.lastDoc,
    this.usesPrimaryFeed,
    this.itemsPreplanned,
    this.nextTypesensePage,
  );

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
  final bool itemsPreplanned;
  final int? nextTypesensePage;
}
