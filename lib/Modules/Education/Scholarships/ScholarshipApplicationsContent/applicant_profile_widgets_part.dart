part of 'applicant_profile.dart';

extension ApplicantProfileWidgetsPart on _ApplicantProfileState {
  Widget _buildProfileHeader(
    ScholarshipApplicationsContentController controller,
  ) {
    return GestureDetector(
      onTap: () {
        Get.to(() => SocialProfile(userID: controller.userID));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: controller.avatarUrl.value.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: controller.avatarUrl.value,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CupertinoActivityIndicator(radius: 12),
                            errorWidget: (context, url, error) {
                              return Container(
                                color: Colors.grey.withAlpha(50),
                                child: const Icon(Icons.person, size: 30),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.withAlpha(50),
                            child: const Icon(Icons.person, size: 30),
                          ),
                  ),
                ),
                16.pw,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          controller.fullName.value,
                          style: const TextStyle(
                            fontFamily: 'MontserratBold',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        4.pw,
                        RozetContent(size: 15, userID: userID),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${controller.nickname.value}',
                      style: TextStyles.tutoringBranch,
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              AppIcons.right,
              size: 22,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black26,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildText(String title, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableText(
    String title,
    String text, {
    bool isPhone = false,
    bool isEmail = false,
  }) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: GestureDetector(
              onTap: () async {
                if (isPhone) {
                  final url = 'tel:$text';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    AppSnackbar(
                      'common.error'.tr,
                      'scholarship.applicant.phone_open_failed'.tr,
                    );
                  }
                } else if (isEmail) {
                  final url = Uri.encodeFull('mailto:$text');
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    AppSnackbar(
                      'common.error'.tr,
                      'scholarship.applicant.email_open_failed'.tr,
                    );
                  }
                }
              },
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 15,
                  color: Colors.blueAccent.shade400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
