import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/verified_account_repository.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/verified_account_data_list.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/verified_account_model.dart';

part 'become_verified_account_controller_form_part.dart';
part 'become_verified_account_controller_facade_part.dart';
part 'become_verified_account_controller_fields_part.dart';
part 'become_verified_account_controller_runtime_part.dart';

class BecomeVerifiedAccountController extends GetxController {
  static BecomeVerifiedAccountController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureBecomeVerifiedAccountController(
        tag: tag,
        permanent: permanent,
      );

  static BecomeVerifiedAccountController? maybeFind({String? tag}) =>
      _maybeFindBecomeVerifiedAccountController(tag: tag);

  final _state = _BecomeVerifiedAccountControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleBecomeVerifiedAccountInit(this);
  }

  @override
  void onClose() {
    _handleBecomeVerifiedAccountClose(this);
    super.onClose();
  }

  Future<bool> submitApplication() => _submitVerifiedAccountApplication(this);
}
