part of 'application_review.dart';

extension ApplicationReviewContentPart on _ApplicationReviewState {
  Widget _applicantCard(JobApplicationModel app, BuildContext context) {
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
            : app.applicantName.isNotEmpty
                ? app.applicantName
                : app.applicantNickname.isNotEmpty
                    ? app.applicantNickname
                    : fetchedNickname.isNotEmpty
                        ? fetchedNickname
                        : 'pasaj.job_finder.unknown_user'.tr;
        final avatarUrl = ((profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    '') as String)
                .trim()
                .isNotEmpty
            ? ((profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    '') as String)
                .trim()
            : app.applicantPfImage;

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
                    GestureDetector(
                      onTap: () => const ProfileNavigationService()
                          .openSocialProfile(app.userID),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CachedUserAvatar(
                            imageUrl: avatarUrl,
                            radius: 20,
                          ),
                        ),
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
                    _statusChip(app.status),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: TurqButtonTokens.height,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCvPreview(app.userID, name, context),
                    style: TurqButtonTokens.outlinedStyle(
                      borderColor: const Color(0x14000000),
                    ),
                    icon: const Icon(
                      CupertinoIcons.doc_text,
                      size: 16,
                      color: Colors.black,
                    ),
                    label: Text(
                      'pasaj.job_finder.view_cv'.tr,
                      style: TurqButtonTokens.secondaryTextStyle,
                    ),
                  ),
                ),
                if (app.status == 'pending' || app.status == 'reviewing') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: TurqButtonTokens.height,
                          child: OutlinedButton(
                            onPressed: () {
                              controller.updateStatus(app.userID, 'rejected');
                            },
                            style: TurqButtonTokens.outlinedStyle(
                              borderColor: Colors.grey.withAlpha(120),
                            ),
                            child: Text(
                              'pasaj.job_finder.reject'.tr,
                              style: TurqButtonTokens.secondaryTextStyle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (app.status != 'reviewing') ...[
                        Expanded(
                          child: SizedBox(
                            height: TurqButtonTokens.height,
                            child: OutlinedButton(
                              onPressed: () {
                                controller.updateStatus(
                                  app.userID,
                                  'reviewing',
                                );
                              },
                              style: TurqButtonTokens.outlinedStyle(
                                borderColor: Colors.grey.withAlpha(120),
                              ),
                              child: Text(
                                'pasaj.job_finder.review'.tr,
                                style: TurqButtonTokens.secondaryTextStyle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: TurqButtonTokens.height,
                          child: ElevatedButton(
                            onPressed: () {
                              controller.updateStatus(app.userID, 'accepted');
                            },
                            style: TurqButtonTokens.elevatedStyle(),
                            child: Text(
                              'pasaj.job_finder.accept'.tr,
                              style: TurqButtonTokens.primaryTextStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
