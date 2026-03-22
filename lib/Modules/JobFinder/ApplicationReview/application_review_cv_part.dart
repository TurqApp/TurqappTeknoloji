part of 'application_review.dart';

extension ApplicationReviewCvPart on _ApplicationReviewState {
  String _localizedCvLanguage(dynamic rawValue) {
    final raw = (rawValue ?? '').toString().trim();
    final normalized = normalizeCvLanguageValue(raw);
    return normalized.startsWith('cv.language.') ? normalized.tr : raw;
  }

  Widget _statusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'reviewing':
        bgColor = const Color(0xFFEAF2FF);
        textColor = const Color(0xFF2F6FED);
        break;
      case 'accepted':
        bgColor = const Color(0xFFEAF7EE);
        textColor = const Color(0xFF2D8A45);
        break;
      case 'rejected':
        bgColor = const Color(0xFFFCECEC);
        textColor = const Color(0xFFC64242);
        break;
      default:
        bgColor = const Color(0xFFFCF4E4);
        textColor = const Color(0xFFB57911);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'MontserratMedium',
        ),
      ),
    );
  }

  Future<void> _showCvPreview(
    String userID,
    String name,
    BuildContext context,
  ) async {
    final cv = await controller.getApplicantCV(userID);
    if (cv == null) {
      AppSnackbar(
        'pasaj.job_finder.cv_not_found_title'.tr,
        'pasaj.job_finder.cv_not_found_body'.tr,
      );
      return;
    }

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${cv['firstName'] ?? ''} ${cv['lastName'] ?? ''}",
                style: const TextStyle(
                  fontFamily: 'MontserratBold',
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              if ((cv['about'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  cv['about'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
              if (cv['mail'] != null && cv['mail'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  "${'account_center.email'.tr}: ${cv['mail']}",
                  style: const TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 13,
                  ),
                ),
              ],
              if (cv['phone'] != null && cv['phone'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "${'common.phone'.tr}: ${cv['phone']}",
                  style: const TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 13,
                  ),
                ),
              ],
              if (cv['okullar'] != null &&
                  (cv['okullar'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'pasaj.job_finder.education'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ...(cv['okullar'] as List).map((school) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "${school['school']} - ${school['branch']} (${school['lastYear']})",
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 13,
                      ),
                    ),
                  );
                }),
              ],
              if (cv['deneyim'] != null &&
                  (cv['deneyim'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'pasaj.job_finder.experience'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ...(cv['deneyim'] as List).map((experience) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${experience['position']} - ${experience['company']} (${experience['year1']}-${experience['year2']})",
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 13,
                          ),
                        ),
                        if ((experience['description'] as String?)
                                ?.isNotEmpty ==
                            true)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              experience['description'],
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              if (cv['skills'] != null &&
                  (cv['skills'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'pasaj.job_finder.skills'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: (cv['skills'] as List).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        skill.toString(),
                        style: const TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 12,
                          color: Colors.blueAccent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (cv['diller'] != null &&
                  (cv['diller'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'pasaj.job_finder.languages'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ...(cv['diller'] as List).map((language) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(
                          "${_localizedCvLanguage(language['languege'])} ",
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 13,
                          ),
                        ),
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < (language['level'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: i < (language['level'] ?? 0)
                                ? Colors.amber
                                : Colors.grey,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'reviewing':
        return 'pasaj.job_finder.status.reviewing'.tr;
      case 'accepted':
        return 'pasaj.job_finder.status.accepted'.tr;
      case 'rejected':
        return 'pasaj.job_finder.status.rejected'.tr;
      default:
        return 'pasaj.job_finder.status.pending'.tr;
    }
  }
}
