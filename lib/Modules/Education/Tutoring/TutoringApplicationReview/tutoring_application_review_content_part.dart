part of 'tutoring_application_review.dart';

extension _TutoringApplicationReviewContentPart
    on _TutoringApplicationReviewState {
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 52,
      titleSpacing: 8,
      leading: const AppBackButton(),
      title: AppPageTitle('tutoring.applicants_title'.tr),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (controller.applicants.isEmpty) {
          return Center(
            child: Text(
              'tutoring.no_applications'.tr,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.applicants.length,
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
          itemBuilder: (context, index) {
            final app = controller.applicants[index];
            return _buildApplicantCard(app);
          },
        );
      }),
    );
  }

  Widget _buildApplicantCard(TutoringApplicationModel app) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: controller.getApplicantProfile(app.userID),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        final fetchedName = profile != null
            ? '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                .trim()
            : '';
        final fetchedNickname = ((profile?['nickname'] ??
                profile?['username'] ??
                profile?['displayName'] ??
                '') as String)
            .trim();
        final name = fetchedName.isNotEmpty
            ? fetchedName
            : app.tutorName.isNotEmpty
                ? app.tutorName
                : fetchedNickname.isNotEmpty
                    ? fetchedNickname
                    : 'common.unknown_user'.tr;
        final avatarUrl =
            (profile?['avatarUrl'] as String?)?.trim().isNotEmpty == true
                ? (profile?['avatarUrl'] as String).trim()
                : app.tutorImage;
        final normalizedAvatarUrl =
            isDefaultAvatarUrl(avatarUrl) ? '' : avatarUrl;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: normalizedAvatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: normalizedAvatarUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _buildFallbackAvatar(),
                              )
                            : _buildFallbackAvatar(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'MontserratBold',
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fetchedNickname.isNotEmpty
                                ? '@$fetchedNickname'
                                : 'tutoring.application_label'.tr,
                            style: TextStyle(
                              fontFamily: 'MontserratMedium',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(app.timeStamp),
                            style: TextStyle(
                              fontFamily: 'MontserratMedium',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(app.status),
                  ],
                ),
                const SizedBox(height: 10),
                if (app.status == 'pending' || app.status == 'reviewing') ...[
                  _buildPendingActions(app),
                ] else ...[
                  _buildOpenProfileButton(app),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingActions(TutoringApplicationModel app) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () => _openProfile(app.userID),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.grey.withAlpha(120),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'common.open_profile'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () => controller.updateStatus(app.userID, 'rejected'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.grey.withAlpha(120),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'common.reject'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => controller.updateStatus(app.userID, 'accepted'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'common.accept'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenProfileButton(TutoringApplicationModel app) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: () => _openProfile(app.userID),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.grey.withAlpha(120),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Profili Aç',
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }
}
