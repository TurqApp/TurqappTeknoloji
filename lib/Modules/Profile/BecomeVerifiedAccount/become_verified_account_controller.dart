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

  void _bindFormListeners() {
    for (final controller in [
      instagram,
      twitter,
      linkedin,
      tiktok,
      youtube,
      website,
      nickname,
      aciklama,
      eDevletBarcodeNo,
    ]) {
      controller.addListener(_updateCanSubmit);
    }
  }

  bool _hasMeaningfulHandle(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isNotEmpty &&
        value != '@' &&
        value != 'https://' &&
        value != 'http://';
  }

  void _updateCanSubmit() {
    aciklamaText.value = aciklama.text;
    final hasNickname = _hasMeaningfulHandle(nickname);
    final hasSocial = _hasMeaningfulHandle(instagram) ||
        _hasMeaningfulHandle(twitter) ||
        _hasMeaningfulHandle(linkedin) ||
        _hasMeaningfulHandle(tiktok) ||
        _hasMeaningfulHandle(youtube) ||
        _hasMeaningfulHandle(website);
    final requiresBarcode = selectedColor.value == "F44336";
    final hasBarcode = eDevletBarcodeNo.text.trim().isNotEmpty;
    canSubmitApplication.value = hasNickname &&
        hasSocial &&
        hasAcceptedConsent.value &&
        (!requiresBarcode || hasBarcode);
  }

  void toggleConsent(bool? value) {
    hasAcceptedConsent.value = value == true;
    _updateCanSubmit();
  }

  void selectItem(VerifiedAccountModel item, int index) {
    selected.value = item;
    selectedInt.value = index;

    switch (index) {
      case 0:
        selectedColor.value = "2196F3";
        break;
      case 1:
        selectedColor.value = "F44336";
        break;
      case 2:
        selectedColor.value = "FFEB3B";
        break;
      case 3:
        selectedColor.value = "40E0D0";
        break;
      case 4:
        selectedColor.value = "9E9E9E";
        break;
      default:
        selectedColor.value = "000000";
        break;
    }
    _updateCanSubmit();
  }

  void setInstagramDefault() {
    if (instagram.text.isEmpty) instagram.text = "@";
  }

  void setTwitterDefault() {
    if (twitter.text.isEmpty) twitter.text = "@";
  }

  void setLinkedinDefault() {
    if (linkedin.text.isEmpty) linkedin.text = "@";
  }

  void setTiktokDefault() {
    if (tiktok.text.isEmpty) tiktok.text = "@";
  }

  void setYoutubeDefault() {
    if (youtube.text.isEmpty) youtube.text = "@";
  }

  void setWebsiteDefault() {
    if (website.text.isEmpty) website.text = "https://";
  }

  void setNicknameDefault() {
    if (nickname.text.isEmpty) nickname.text = "@";
  }

  void setShowTrue() {
    show.value = true;
  }

  Future<bool> submitApplication() async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    final uid = CurrentUserService.instance.effectiveUserId;
    try {
      if (uid.isEmpty) {
        AppSnackbar('common.error'.tr, 'become_verified.session_missing'.tr);
        return false;
      }

      final currentUser = CurrentUserService.instance.currentUser;
      final normalizedRequestedNickname = normalizeNicknameInput(nickname.text);
      final currentNickname = (currentUser?.nickname ?? '').trim();
      await _verifiedAccountRepository.submitApplication({
        "userID": uid,
        "selected": selected.value?.title,
        "status": "pending",
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "aciklama": aciklama.text,
        "website": website.text,
        "instagram": instagram.text,
        "twitter": twitter.text,
        "youtube": youtube.text,
        "linkedin": linkedin.text,
        "tiktok": tiktok.text,
        "talepNickname": nickname.text,
        "talepNicknameNormalized": normalizedRequestedNickname,
        "eDevletBarCodeNo": eDevletBarcodeNo.text,
        "currentNickname": currentNickname,
        "turqappUserLink": _buildTurqAppUserLink(
          currentNickname: currentNickname,
          uid: uid,
        ),
        "talepNicknameLink": normalizedRequestedNickname.isEmpty
            ? ''
            : buildTurqAppProfileUrl(normalizedRequestedNickname),
        "instagramUrl": _buildSocialUrl(
          instagram.text,
          prefix: 'https://instagram.com/',
        ),
        "twitterUrl": _buildSocialUrl(
          twitter.text,
          prefix: 'https://x.com/',
        ),
        "youtubeUrl": _buildSocialUrl(
          youtube.text,
          prefix: 'https://youtube.com/@',
        ),
        "linkedinUrl": _buildSocialUrl(
          linkedin.text,
          prefix: 'https://linkedin.com/in/',
        ),
        "tiktokUrl": _buildSocialUrl(
          tiktok.text,
          prefix: 'https://tiktok.com/@',
        ),
        "websiteUrl": normalizeWebsiteUrl(website.text),
      });
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        AppSnackbar('common.info'.tr, 'become_verified.already_received'.tr);
        bodySelection.value = 3;
        existingApplicationStatus.value = 'pending';
        await _verifiedAccountRepository.fetchApplicationState(
          uid,
          forceRefresh: true,
        );
        return false;
      }
      AppSnackbar('common.error'.tr, 'become_verified.submit_failed'.tr);
      return false;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'become_verified.submit_failed'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  String _buildSocialUrl(
    String raw, {
    required String prefix,
  }) {
    final normalized = normalizeNicknameInput(raw);
    if (normalized.isEmpty) return '';
    return '$prefix$normalized';
  }

  String _buildTurqAppUserLink({
    required String currentNickname,
    required String uid,
  }) {
    final normalized = normalizeNicknameInput(currentNickname);
    if (normalized.isNotEmpty) {
      return buildTurqAppProfileUrl(normalized);
    }
    return buildTurqAppProfileUrl(uid);
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
