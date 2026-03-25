part of 'notify_lookup_repository.dart';

class NotifyPostLookup {
  const NotifyPostLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final PostsModel? model;
  final DateTime cachedAt;
}

class NotifyChatLookup {
  const NotifyChatLookup({
    required this.otherUser,
    required this.cachedAt,
  });

  final String otherUser;
  final DateTime cachedAt;
}

class NotifyJobLookup {
  const NotifyJobLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final JobModel? model;
  final DateTime cachedAt;
}

class NotifyTutoringLookup {
  const NotifyTutoringLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final TutoringModel? model;
  final DateTime cachedAt;
}

class NotifyMarketLookup {
  const NotifyMarketLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final MarketItemModel? model;
  final DateTime cachedAt;
}
