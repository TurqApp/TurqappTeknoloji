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
part 'become_verified_account_controller_submission_part.dart';

class BecomeVerifiedAccountController extends GetxController {
  static BecomeVerifiedAccountController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BecomeVerifiedAccountController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static BecomeVerifiedAccountController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<BecomeVerifiedAccountController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BecomeVerifiedAccountController>(tag: tag);
  }

  final VerifiedAccountRepository _verifiedAccountRepository =
      VerifiedAccountRepository.ensure();
  final RxString aciklamaText = "".obs;
  final RxBool canSubmitApplication = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool hasAcceptedConsent = false.obs;
  final RxString existingApplicationStatus = ''.obs;
  var selected = Rx<VerifiedAccountModel?>(null);
  Rx<String> selectedColor = "2196F3".obs;
  var selectedInt = 0.obs;
  var bodySelection = 0.obs;

  final instagram = TextEditingController();
  final twitter = TextEditingController();
  final linkedin = TextEditingController();
  final tiktok = TextEditingController();
  final youtube = TextEditingController();
  final website = TextEditingController();

  final nickname = TextEditingController();
  final aciklama = TextEditingController();

  final eDevletBarcodeNo = TextEditingController();

  var show = false.obs;

  @override
  void onInit() {
    super.onInit();
    _verifiedAccountRepository
        .fetchApplicationState(
      CurrentUserService.instance.effectiveUserId,
    )
        .then((state) {
      existingApplicationStatus.value = state?.status ?? '';
      if (state?.isPending == true) {
        bodySelection.value = 3;
      } else {
        selectItem(verifiedAccountData.first, 0);
        _bindFormListeners();
        _updateCanSubmit();
      }
    });
  }

  @override
  void onClose() {
    instagram.dispose();
    twitter.dispose();
    linkedin.dispose();
    tiktok.dispose();
    youtube.dispose();
    website.dispose();
    nickname.dispose();
    aciklama.dispose();
    eDevletBarcodeNo.dispose();
    super.onClose();
  }
}
