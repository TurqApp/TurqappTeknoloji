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

  String _selectedBadgeColorForTitle(String title) {
    switch (title.trim().toLowerCase()) {
      case 'mavi':
        return "2196F3";
      case 'kırmızı':
      case 'kirmizi':
        return "F44336";
      case 'sarı':
      case 'sari':
        return "FFEB3B";
      case 'turkuaz':
        return "40E0D0";
      case 'gri':
        return "9E9E9E";
      case 'siyah':
        return "000000";
      default:
        return "2196F3";
    }
  }

  void selectItem(VerifiedAccountModel item, int index) {
    selected.value = item;
    selectedInt.value = index;
    selectedColor.value = _selectedBadgeColorForTitle(item.title);
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
