part of 'edit_profile.dart';

extension _EditProfileSettingsPart on _EditProfileState {
  Widget _buildOtherInfoSection() {
    return Column(
      children: [
        _buildSectionDivider('edit_profile.other_info'.tr),
        const SizedBox(height: 12),
        _buildNavigationTiles(),
        _buildUpdateButton(),
        12.ph,
        GestureDetector(
          onTap: () {
            Get.to(() => DeleteAccount());
          },
          child: Text(
            'edit_profile.delete_account'.tr,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        12.ph,
      ],
    );
  }

  Widget _buildNavigationTiles() {
    return Column(
      children: [
        _buildActionTile(
          onTap: () async {
            final currentPrivacy = currentUserService.isPrivate;
            await currentUserService
                .updateFields({'isPrivate': !currentPrivacy});
          },
          leading: Row(
            children: [
              const Icon(CupertinoIcons.lock, color: Colors.black, size: 20),
              const SizedBox(width: 12),
              Text(
                'edit_profile.privacy'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ],
          ),
          trailing: Obx(
            () => TurqAppToggle(
              isOn: currentUserService.currentUserRx.value?.gizliHesap == true,
            ),
          ),
        ),
        _buildChevronTile(
          icon: CupertinoIcons.link,
          label: 'edit_profile.links'.tr,
          onTap: () {
            Get.to(() => SocialMediaLinks());
          },
        ),
        _buildChevronTile(
          icon: CupertinoIcons.text_alignleft,
          label: 'biography.title'.tr,
          onTap: () {
            Get.to(() => BiographyMaker());
          },
        ),
        _buildChevronTile(
          icon: CupertinoIcons.bag,
          label: 'job_selector.title'.tr,
          onTap: () {
            Get.to(() => JobSelector());
          },
        ),
        _buildChevronTile(
          icon: CupertinoIcons.at,
          label: 'edit_profile.contact_info'.tr,
          onTap: () {
            Get.to(() => ProfileContact());
          },
        ),
        _buildChevronTile(
          icon: CupertinoIcons.map_pin_ellipse,
          label: 'edit_profile.address_info'.tr,
          onTap: () {
            Get.to(() => AddressSelector());
          },
        ),
        _buildChevronTile(
          icon: CupertinoIcons.doc_person,
          label: 'edit_profile.career_profile'.tr,
          onTap: () {
            Get.to(() => Cv());
          },
        ),
      ],
    );
  }

  Widget _buildChevronTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _buildActionTile(
      onTap: onTap,
      leading: Row(
        children: [
          Icon(icon, color: Colors.black, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildActionTile({
    required VoidCallback onTap,
    required Widget leading,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: leading),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    if (_updating) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: const CupertinoActivityIndicator(color: Colors.white),
      );
    }

    return TurqAppButton(
      key: const ValueKey(IntegrationTestKeys.actionEditProfileUpdate),
      onTap: () async {
        if (_updating) return;
        _updateEditProfileState(() => _updating = true);
        await controller.updateProfileInfo();
        if (!mounted) return;
        _updateEditProfileState(() => _updating = false);
      },
      text: 'common.update'.tr,
    );
  }
}
