part of 'become_verified_account.dart';

extension _BecomeVerifiedAccountStepsPart on _BecomeVerifiedAccountState {
  Widget _buildVerifiedScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                AppBackButton(
                  onTap: () {
                    if (controller.bodySelection.value != 0) {
                      controller.bodySelection--;
                    } else {
                      Get.back();
                    }
                  },
                  icon: CupertinoIcons.arrow_left,
                  iconSize: 20,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(
                  () => Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    child: _buildStepBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    return switch (controller.bodySelection.value) {
      0 => build1(),
      1 => build2(),
      2 => build3(),
      3 => build4(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget build1() {
    return Obx(
      () => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: HexColor.hex(controller.selectedColor.value),
                      size: 45,
                    ),
                    Text(
                      'settings.become_verified'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'become_verified.intro'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 25),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: verifiedAccountData.length,
                      itemBuilder: (context, index) {
                        final item = verifiedAccountData[index];
                        final isSelected =
                            controller.selected.value?.title == item.title;
                        final localizedDesc = _localizedBadgeDesc(item.title);
                        final detailLines = localizedDesc
                            .split('\n')
                            .map((line) => line.trim())
                            .where((line) => line.isNotEmpty)
                            .toList(growable: false);
                        final secondaryDetail =
                            detailLines.length > 1 ? detailLines[1] : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: TextButton(
                            onPressed: () {
                              controller.selectItem(item, index);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.transparent,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? HexColor.hex(
                                          controller.selectedColor.value,
                                        )
                                      : Colors.grey.withAlpha(80),
                                ),
                              ),
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _localizedBadgeTitle(item.title),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontFamily: 'MontserratBold',
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.indigo,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (isSelected && secondaryDetail.isNotEmpty)
                                    Text(
                                      secondaryDetail,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  if (isSelected &&
                                      _requiresAnnualRenewal(
                                        controller.selectedInt.value,
                                      ))
                                    Text(
                                      'become_verified.annual_renewal'.tr,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: 'MontserratBold',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'become_verified.footer'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                    TurqAppButton(
                      text: 'common.continue'.tr,
                      onTap: () {
                        controller.bodySelection.value++;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget build2() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: HexColor.hex(controller.selectedColor.value),
              size: 50,
            ),
            const SizedBox(height: 15),
            Text(
              _localizedBadgeTitle(
                verifiedAccountData[controller.selectedInt.value].title,
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _localizedBadgeDesc(
                verifiedAccountData[controller.selectedInt.value].title,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            color: Colors.white,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _featureRow(
                  'become_verified.feature_ads'.tr,
                  trailingText: 'become_verified.feature_limited_ads'.tr,
                ),
                _featureRow(
                  'become_verified.feature_post_boost'.tr,
                  trailingText: 'become_verified.feature_highest'.tr,
                ),
                _featureRow(
                  'become_verified.feature_video_download'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_long_video'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_statistics'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_username'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_verification_mark'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_account_protection'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_channel_creation'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_priority_support'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_scheduled_video'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_unlimited_listings'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_unlimited_links'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_assistant'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_scheduled_content'.tr,
                  showCheck: true,
                ),
                _featureRow(
                  'become_verified.feature_character_limit'.tr,
                  trailingText:
                      'become_verified.feature_character_limit_value'.tr,
                  addBottomPadding: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'become_verified.loss_title'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'become_verified.loss_body'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TurqAppButton(
          onTap: () {
            controller.bodySelection.value++;
          },
          text: 'common.continue'.tr,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget build3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'become_verified.step_social_accounts'.tr,
          style: const TextStyle(fontSize: 18, fontFamily: 'MontserratBold'),
        ),
        const SizedBox(height: 12),
        ..._buildSocialField(
          controller.instagram,
          'Instagram',
          'assets/icons/instagramx.webp',
          controller.setInstagramDefault,
        ),
        ..._buildSocialField(
          controller.twitter,
          'Twitter',
          'assets/icons/twitterx.webp',
          controller.setTwitterDefault,
        ),
        ..._buildSocialField(
          controller.tiktok,
          'TikTok',
          'assets/icons/tiktokx.webp',
          controller.setTiktokDefault,
        ),
        const SizedBox(height: 25),
        Text(
          'become_verified.step_requested_username'.tr,
          style: const TextStyle(fontSize: 18, fontFamily: 'MontserratBold'),
        ),
        const SizedBox(height: 12),
        _buildCustomInput(
          controller.nickname,
          'become_verified.requested_username_hint'.tr,
          controller.setNicknameDefault,
        ),
        const SizedBox(height: 25),
        Text(
          'become_verified.step_social_confirmation'.tr,
          style: const TextStyle(fontSize: 18, fontFamily: 'MontserratBold'),
        ),
        const SizedBox(height: 12),
        Text(
          'become_verified.social_confirmation_body'.tr,
          style: const TextStyle(fontSize: 15, fontFamily: 'Montserrat'),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _socialLinkIcon(
              'assets/icons/twitterx.webp',
              Uri.parse('https://x.com/turqapp'),
            ),
            _socialLinkIcon(
              'assets/icons/instagram.webp',
              Uri.parse('https://instagram.com/turqapp'),
            ),
            _socialLinkIcon(
              'assets/icons/tiktokx.webp',
              Uri.parse('https://tiktok.com/@turqapp'),
            ),
            _socialLinkIcon(
              'assets/icons/linkedin.webp',
              Uri.parse('https://linkedin.com/in/turqapp'),
            ),
            _socialLinkIcon(
              'assets/icons/facebook.webp',
              Uri.parse('https://facebook.com/turqapp'),
            ),
          ],
        ),
        15.ph,
        Obx(
          () => GestureDetector(
            onTap: () =>
                controller.toggleConsent(!controller.hasAcceptedConsent.value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: controller.hasAcceptedConsent.value,
                  onChanged: controller.toggleConsent,
                  activeColor: Colors.black,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'become_verified.consent'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'MontserratMedium',
                        color: Colors.black,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (controller.selectedInt.value == 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Text(
                'become_verified.step_barcode'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 12),
              _buildCustomInput(
                controller.eDevletBarcodeNo,
                'become_verified.barcode_hint'.tr,
              ),
            ],
          ),
        if (controller.canSubmitApplication.value)
          GestureDetector(
            onTap: () async {
              final ok = await controller.submitApplication();
              if (ok) {
                controller.bodySelection++;
              }
            },
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 25),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'become_verified.submit'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'MontserratBold',
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget build4() {
    return SizedBox(
      height: Get.height * 0.72,
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0x12000000)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F6F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Colors.black,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'become_verified.received_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'become_verified.received_body'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'become_verified.received_note'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 18),
              TurqAppButton(
                text: 'common.ok'.tr,
                onTap: () {
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialLinkIcon(String assetPath, Uri url) {
    return GestureDetector(
      onTap: () => confirmAndLaunchExternalUrl(url),
      child: Image.asset(
        assetPath,
        height: 40,
      ),
    );
  }

  Widget _featureRow(
    String title, {
    String? trailingText,
    bool showCheck = false,
    bool addBottomPadding = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: addBottomPadding ? 15 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratBold',
            ),
          ),
          if (showCheck)
            const Icon(
              CupertinoIcons.checkmark_circle,
              color: Colors.green,
              size: 18,
            )
          else if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Montserrat',
              ),
            ),
        ],
      ),
    );
  }
}
