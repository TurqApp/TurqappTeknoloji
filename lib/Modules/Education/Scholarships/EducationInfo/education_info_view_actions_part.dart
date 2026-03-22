part of 'education_info_view.dart';

extension _EducationInfoViewActionsPart on _EducationInfoViewState {
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: BackButtons(text: 'education_info.title'.tr),
        ),
        PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: 'education_info.reset_menu'.tr,
              icon: CupertinoIcons.restart,
              onTap: () {
                noYesAlert(
                  title: 'education_info.reset_title'.tr,
                  message: 'education_info.reset_body'.tr,
                  cancelText: 'common.cancel'.tr,
                  yesText: 'common.reset'.tr,
                  onYesPressed: () async {
                    final userId = _currentUserService.userId;
                    if (userId.isEmpty) return;
                    controller.clearFields();
                    await _userRepository.updateUserFields(
                      userId,
                      {
                        ...scopedUserUpdate(
                          scope: 'education',
                          values: {
                            'educationLevel': '',
                            'ortaOkul': '',
                            'lise': '',
                            'universite': '',
                            'fakulte': '',
                            'bolum': '',
                            'sinif': '',
                          },
                        ),
                        ...scopedUserUpdate(
                          scope: 'profile',
                          values: {
                            'ulke': '',
                            'il': '',
                            'ilce': '',
                          },
                        ),
                      },
                    );
                    await controller.loadSavedData();
                    controller.hasMiddleSchoolData.value = false;
                    controller.hasHighSchoolData.value = false;
                    controller.hasHigherEducationData.value = false;
                    controller.selectedEducationLevel.value = '';
                    AppSnackbar(
                      'common.success'.tr,
                      'education_info.reset_success'.tr,
                    );
                  },
                );
              },
            ),
          ],
          buttonBuilder: (context, showMenu) => AppHeaderActionButton(
            onTap: showMenu,
            child: const Icon(
              Icons.more_vert,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
