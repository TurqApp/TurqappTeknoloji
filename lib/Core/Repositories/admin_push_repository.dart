import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'admin_push_repository_query_part.dart';
part 'admin_push_repository_action_part.dart';
part 'admin_push_repository_facade_part.dart';
part 'admin_push_repository_filter_part.dart';
part 'admin_push_repository_models_part.dart';
part 'admin_push_repository_support_part.dart';

class AdminPushRepository extends GetxService {
  static const String _defaultPushImageUrl = _adminPushDefaultImageUrl;

  static AdminPushRepository? maybeFind() => _maybeFindAdminPushRepository();

  static AdminPushRepository ensure() => _ensureAdminPushRepository();
}
