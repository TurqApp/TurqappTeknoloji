part of 'agenda_controller.dart';

enum FeedViewMode { forYou, following, city }

class _AgendaSourcePage {
  const _AgendaSourcePage({
    required this.items,
    required this.lastDoc,
    required this.usesPrimaryFeed,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
}
