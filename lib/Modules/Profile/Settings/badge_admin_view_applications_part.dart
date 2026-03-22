part of 'badge_admin_view.dart';

class _ApplicationsSection extends StatelessWidget {
  const _ApplicationsSection({
    required this.docs,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.badges.applications_title'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin.badges.applications_help'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'admin.badges.no_applications'.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            )
          else
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ApplicationCard(data: doc.data()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatefulWidget {
  const _ApplicationCard({
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  bool _approving = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final selected = (data['selected'] ?? '').toString().trim();
    final currentNickname = (data['currentNickname'] ?? '').toString().trim();
    final requestedNickname = (data['talepNickname'] ?? '').toString().trim();
    final userId = (data['userID'] ?? '').toString().trim();
    final timeStamp = (data['timeStamp'] as num?)?.toInt() ?? 0;
    final status = (data['status'] ?? 'pending').toString().trim();
    final links = <_ApplicationLink>[
      _ApplicationLink(
        label: 'Instagram',
        url: _pickSocialUrl(
          data['instagramUrl'],
          data['instagram'],
          prefix: 'https://instagram.com/',
        ),
      ),
      _ApplicationLink(
        label: 'X',
        url: _pickSocialUrl(
          data['twitterUrl'],
          data['twitter'],
          prefix: 'https://x.com/',
        ),
      ),
      _ApplicationLink(
        label: 'TikTok',
        url: _pickSocialUrl(
          data['tiktokUrl'],
          data['tiktok'],
          prefix: 'https://tiktok.com/@',
        ),
      ),
      _ApplicationLink(
        label: 'YouTube',
        url: _pickSocialUrl(
          data['youtubeUrl'],
          data['youtube'],
          prefix: 'https://youtube.com/@',
        ),
      ),
      _ApplicationLink(
        label: 'LinkedIn',
        url: _pickSocialUrl(
          data['linkedinUrl'],
          data['linkedin'],
          prefix: 'https://linkedin.com/in/',
        ),
      ),
      _ApplicationLink(
        label: 'Website',
        url: _pickWebsiteUrl(data['websiteUrl'], data['website']),
      ),
    ].where((item) => item.url.isNotEmpty).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestedNickname.isEmpty ? '@-' : requestedNickname,
                      style: const TextStyle(
                        fontFamily: 'MontserratBold',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: userId.isEmpty
                          ? null
                          : () => Get.to(() => SocialProfile(userID: userId)),
                      child: Text(
                        'TurqApp: ${currentNickname.isEmpty ? '@-' : currentNickname}',
                        style: TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 12,
                          color: userId.isEmpty ? Colors.black54 : Colors.blue,
                          decoration: userId.isEmpty
                              ? TextDecoration.none
                              : TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UID: $userId',
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selected.isEmpty
                      ? 'admin.badges.no_badge_selected'.tr
                      : selected,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'admin.badges.status'.trParams(<String, String>{'status': status}),
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          if (timeStamp > 0) ...[
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timeStamp),
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: links
                  .map((item) => _LinkChip(link: item))
                  .toList(growable: false),
            ),
          ],
          if (status != 'approved' &&
              selected.isNotEmpty &&
              userId.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _approving ? null : () => _approve(userId, selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _approving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined, size: 18),
                label: Text(
                  'admin.badges.approve_and_assign'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approve(String userId, String rozet) async {
    setState(() {
      _approving = true;
    });
    try {
      final isPrimaryAdmin = await AdminAccessService.isPrimaryAdmin();
      if (!isPrimaryAdmin) {
        await _approvalRepository.createApproval(
          type: 'badge_change',
          title: 'admin.badges.application_approval_title'.tr,
          summary: 'admin.badges.application_approval_summary'.trParams(
            <String, String>{
              'nickname':
                  (widget.data['talepNickname'] ?? '').toString().trim(),
              'badge': rozet,
            },
          ),
          targetUserId: userId,
          targetNickname:
              (widget.data['currentNickname'] ?? '').toString().trim(),
          payload: <String, dynamic>{
            'userId': userId,
            'rozet': rozet,
          },
        );
        AppSnackbar(
          'admin.badges.title'.tr,
          'admin.badges.application_sent_for_approval'.tr,
        );
        return;
      }

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('setUserBadgeByUserId');
      await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'rozet': rozet,
      });
      AppSnackbar(
        'admin.badges.title'.tr,
        'admin.badges.application_approved'.tr,
      );
    } on FirebaseFunctionsException catch (e) {
      final message = e.message ?? 'admin.badges.application_approve_failed'.tr;
      AppSnackbar('support.error_title'.tr, message);
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.badges.application_approve_failed'.tr}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _approving = false;
        });
      }
    }
  }

  String _formatTimestamp(int value) {
    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${dt.year} $hh:$min';
  }

  String _pickSocialUrl(Object? urlValue, Object? rawValue,
      {required String prefix}) {
    final url = (urlValue ?? '').toString().trim();
    if (url.isNotEmpty) return url;
    final raw = normalizeHandleInput((rawValue ?? '').toString());
    if (raw.isEmpty) return '';
    return '$prefix$raw';
  }

  String _pickWebsiteUrl(Object? urlValue, Object? rawValue) {
    final url = normalizeWebsiteUrl((urlValue ?? '').toString());
    if (url.isNotEmpty) return url;
    return normalizeWebsiteUrl((rawValue ?? '').toString());
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.link,
  });

  final _ApplicationLink link;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => confirmAndLaunchExternalUrl(Uri.parse(link.url)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          link.label,
          style: const TextStyle(
            fontFamily: 'MontserratBold',
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _ApplicationLink {
  _ApplicationLink({
    required this.label,
    Object? url,
  }) : url = (url ?? '').toString().trim();

  final String label;
  final String url;
}
