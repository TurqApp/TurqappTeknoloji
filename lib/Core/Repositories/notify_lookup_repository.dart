import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'notify_lookup_repository_query_part.dart';
part 'notify_lookup_repository_cache_part.dart';

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

class NotifyLookupRepository extends GetxService {
  NotifyLookupRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _postLookupTtl = Duration(seconds: 30);
  static const Duration _chatLookupTtl = Duration(seconds: 30);
  static const Duration _jobLookupTtl = Duration(seconds: 30);
  static const Duration _tutoringLookupTtl = Duration(seconds: 30);
  static const Duration _marketLookupTtl = Duration(seconds: 30);
  static const Duration _staleRetention = Duration(minutes: 3);
  static const int _maxLookupEntries = 300;

  final Map<String, NotifyPostLookup> _postLookupCache =
      <String, NotifyPostLookup>{};
  final Map<String, NotifyChatLookup> _chatLookupCache =
      <String, NotifyChatLookup>{};
  final Map<String, NotifyJobLookup> _jobLookupCache =
      <String, NotifyJobLookup>{};
  final Map<String, NotifyTutoringLookup> _tutoringLookupCache =
      <String, NotifyTutoringLookup>{};
  final Map<String, NotifyMarketLookup> _marketLookupCache =
      <String, NotifyMarketLookup>{};

  static NotifyLookupRepository? maybeFind() {
    final isRegistered = Get.isRegistered<NotifyLookupRepository>();
    if (!isRegistered) return null;
    return Get.find<NotifyLookupRepository>();
  }

  static NotifyLookupRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NotifyLookupRepository(), permanent: true);
  }
}
