import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'follow_repository_query_part.dart';
part 'follow_repository_action_part.dart';
part 'follow_repository_models_part.dart';
part 'follow_repository_cache_part.dart';
part 'follow_repository_class_part.dart';

class FollowWriteResult {
  final bool nowFollowing;
  final bool limitReached;

  const FollowWriteResult({
    required this.nowFollowing,
    required this.limitReached,
  });
}
