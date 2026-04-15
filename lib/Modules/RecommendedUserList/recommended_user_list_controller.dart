import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/recommended_users_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Models/recommended_user_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'recommended_user_list_controller_facade_part.dart';
part 'recommended_user_list_controller_fields_part.dart';
part 'recommended_user_list_controller_runtime_part.dart';

class RecommendedUserListController extends GetxController {
  final _state = _RecommendedUserListControllerState();

  @override
  void onInit() {
    super.onInit();
    // İlk feed turunda slotun en sona düşmüş gibi görünmemesi için
    // ön yüklemeyi geciktirmeden başlat.
    _RecommendedUserListControllerRuntimeX(this)._preloadInBackground();
  }
}
