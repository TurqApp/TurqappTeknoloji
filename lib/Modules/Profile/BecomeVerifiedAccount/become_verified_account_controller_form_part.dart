part of 'become_verified_account_controller.dart';

extension BecomeVerifiedAccountControllerFormPart
    on BecomeVerifiedAccountController {
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
}
