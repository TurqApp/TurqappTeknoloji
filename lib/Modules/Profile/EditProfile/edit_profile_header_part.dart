part of 'edit_profile.dart';

extension _EditProfileHeaderPart on _EditProfileState {
  Widget _buildEditProfileScaffold(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenEditProfile),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'edit_profile.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _buildPersonalInfoSection(),
                      15.ph,
                      _buildOtherInfoSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Obx(() {
                  final preview = controller.croppedImage.value;

                  return ClipOval(
                    child: SizedBox(
                      width: (Get.width * 0.31).clamp(96.0, 120.0),
                      height: (Get.width * 0.31).clamp(96.0, 120.0),
                      child: preview != null
                          ? Image.memory(preview, fit: BoxFit.cover)
                          : (_avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  memCacheHeight: 400,
                                  imageUrl: _avatarUrl,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: DefaultAvatar(radius: 56),
                                )),
                    ),
                  );
                }),
                PullDownButton(
                  key: ValueKey(_avatarUrl),
                  itemBuilder: (context) => [
                    PullDownMenuItem(
                      onTap: () => controller.pickImage(
                        source: ImageSource.camera,
                      ),
                      title: 'profile_photo.camera'.tr,
                      icon: CupertinoIcons.camera,
                    ),
                    PullDownMenuItem(
                      onTap: () => controller.pickImage(
                        source: ImageSource.gallery,
                      ),
                      title: 'profile_photo.gallery'.tr,
                      icon: CupertinoIcons.photo,
                    ),
                    if (controller.hasCustomProfilePhoto)
                      PullDownMenuItem(
                        onTap: controller.removeProfilePhoto,
                        title: 'common.remove'.tr,
                        icon: CupertinoIcons.trash,
                      ),
                  ],
                  buttonBuilder: (context, showMenu) => GestureDetector(
                    onTap: showMenu,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        15.ph,
        _buildSectionDivider('edit_profile.personal_info'.tr),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNameField(
                controller: controller.firstNameController,
                hint: 'edit_profile.first_name_hint'.tr,
                fieldKey: const ValueKey(
                  IntegrationTestKeys.inputEditProfileFirstName,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNameField(
                controller: controller.lastNameController,
                hint: 'edit_profile.last_name_hint'.tr,
                fieldKey: const ValueKey(
                  IntegrationTestKeys.inputEditProfileLastName,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              Get.to(() => EditorNickname())?.then((_) {
                currentUserService.forceRefresh();
              });
            },
            child: _buildInfoTile(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '@$_nickname',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  Text(
                    'common.change'.tr,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Obx(() {
            final verified = currentUserService.emailVerifiedRx.value;
            return GestureDetector(
              onTap: () {
                if (!verified) {
                  Get.to(() => EditorEmail());
                }
              },
              child: _buildInfoTile(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (verified)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'common.verified'.tr,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'common.verify'.tr,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Obx(() {
            final currentUser = currentUserService.currentUserRx.value;
            final reactivePhone = controller.phoneNumber.value.trim();
            final resolvedPhone =
                (currentUser?.phoneNumber.trim().isNotEmpty == true)
                    ? currentUser!.phoneNumber.trim()
                    : reactivePhone;
            final displayPhone = _formatDisplayPhone(resolvedPhone);
            return GestureDetector(
              onTap: () {
                Get.to(() => EditorPhoneNumber())?.then((_) {
                  currentUserService.forceRefresh();
                });
              },
              child: _buildInfoTile(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayPhone.isNotEmpty
                            ? displayPhone
                            : 'common.not_specified'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'common.change'.tr,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String hint,
    required Key fieldKey,
  }) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: TextField(
          key: fieldKey,
          controller: controller,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
            ),
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: 'MontserratMedium',
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withAlpha(100))),
        12.pw,
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratBold',
          ),
        ),
        12.pw,
        Expanded(child: Divider(color: Colors.grey.withAlpha(100))),
      ],
    );
  }

  Widget _buildInfoTile({required Widget child}) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: child,
      ),
    );
  }
}
