import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Models/current_user_model.dart';

part 'user_repository_profile_part.dart';
part 'user_repository_query_part.dart';
part 'user_repository_models_part.dart';

class UserRepository extends GetxService {
  final Map<String, _TimedUserLookup<bool>> _existsCache =
      <String, _TimedUserLookup<bool>>{};
  final Map<String, _TimedUserLookup<Map<String, dynamic>?>> _queryCache =
      <String, _TimedUserLookup<Map<String, dynamic>?>>{};

  static UserRepository? maybeFind() {
    final isRegistered = Get.isRegistered<UserRepository>();
    if (!isRegistered) return null;
    return Get.find<UserRepository>();
  }

  static UserRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserRepository(), permanent: true);
  }

  UserProfileCacheService get _cache {
    return UserProfileCacheService.ensure();
  }
}
