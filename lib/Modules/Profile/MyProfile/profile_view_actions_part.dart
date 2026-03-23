part of 'profile_view.dart';

extension _ProfileViewActionsPart on _ProfileViewState {
  Widget _buildTopHeaderRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: _openAboutProfile,
                    child: Text(
                      _myIosSafeNickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: AppFontFamilies.mbold,
                      ),
                    ),
                  ),
                ),
                if (_myIosSafeNickname.trim().isNotEmpty) ...[
                  RozetContent(
                    size: 15,
                    userID: _myUserId,
                    leftSpacing: 6,
                    rozetValue: normalizeRozetValue(
                      controller.headerRozet.value,
                    ).isNotEmpty
                        ? normalizeRozetValue(controller.headerRozet.value)
                        : normalizeRozetValue(userService.rozet),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHeaderActionButton(
                key: const ValueKey(IntegrationTestKeys.actionProfileOpenQr),
                size: 36,
                onTap: _openQrCode,
                child: Icon(
                  CupertinoIcons.qrcode,
                  color: AppColors.textBlack,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              AppHeaderActionButton(
                key: const ValueKey(IntegrationTestKeys.actionProfileOpenChat),
                size: 36,
                onTap: _openChatListing,
                child: Icon(
                  CupertinoIcons.mail,
                  color: AppColors.textBlack,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              AppHeaderActionButton(
                key: const ValueKey(
                  IntegrationTestKeys.actionProfileOpenSettings,
                ),
                size: 36,
                onTap: _openSettings,
                child: Icon(
                  CupertinoIcons.gear,
                  color: AppColors.textBlack,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageAndButtonsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _handleProfileImageTap,
                    onLongPress: _showProfileImagePreview,
                    child: _buildProfileImageWithBorder(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _openStoryMakerAndRefresh,
                      child: Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              12.pw,
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey(
                          IntegrationTestKeys.actionProfileEdit,
                        ),
                        onTap: _openEditProfile,
                        child: _buildHeaderButton("profile.edit".tr),
                      ),
                    ),
                    12.pw,
                    Expanded(
                      child: GestureDetector(
                        onTap: _openMyStatistics,
                        child: _buildHeaderButton("profile.statistics".tr),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(String text) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontFamily: "MontserratBold",
        ),
      ),
    );
  }
}
