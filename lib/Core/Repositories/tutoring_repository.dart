import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/Education/tutoring_review_model.dart';

part 'tutoring_repository_query_part.dart';
part 'tutoring_repository_action_part.dart';
part 'tutoring_repository_cache_part.dart';

class TutoringRepository extends GetxService {
  TutoringRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'tutoring_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;
  static const int _thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    _handleTutoringRepositoryInit(this);
  }

  static TutoringRepository? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringRepository>();
    if (!isRegistered) return null;
    return Get.find<TutoringRepository>();
  }

  static TutoringRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringRepository(), permanent: true);
  }
}

class TutoringPage {
  const TutoringPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TutoringModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedValue<T> {
  const _TimedValue({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
