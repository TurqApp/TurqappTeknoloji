import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';

part 'explore_repository_models_part.dart';
part 'explore_repository_facade_part.dart';
part 'explore_repository_cache_part.dart';
part 'explore_repository_query_part.dart';
part 'explore_repository_page_part.dart';

class ExploreRepository extends GetxService {
  ExploreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppFirestore.instance;

  final FirebaseFirestore _firestore;
  SharedPreferences? _prefs;

  static ExploreRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ExploreRepository>();
    if (!isRegistered) return null;
    return Get.find<ExploreRepository>();
  }

  static ExploreRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ExploreRepository(), permanent: true);
  }
}
