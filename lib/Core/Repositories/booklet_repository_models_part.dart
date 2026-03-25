part of 'booklet_repository.dart';

class BookletPage {
  const BookletPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<BookletModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedBooklets {
  const _TimedBooklets({
    required this.items,
    required this.cachedAt,
  });

  final List<BookletModel> items;
  final DateTime cachedAt;
}
