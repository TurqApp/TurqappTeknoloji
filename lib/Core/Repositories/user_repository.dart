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
part 'user_repository_fields_part.dart';

class UserRepository extends GetxService {
  final _state = _UserRepositoryState();

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
}
