part of 'my_applications.dart';

extension MyApplicationsCardPart on _MyApplicationsState {
  Widget _applicationCard(JobApplicationModel app) {
    final status = app.status;
    final canCancel = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
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
                  width: 72,
                  height: 72,
                  child: app.companyLogo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: app.companyLogo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _fallbackLogo(),
                        )
                      : _fallbackLogo(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.jobTitle.isNotEmpty
                          ? app.jobTitle
                          : 'pasaj.job_finder.default_job_title'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.companyName.isNotEmpty
                          ? app.companyName
                          : 'pasaj.job_finder.default_company'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statusChip(status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(
                              app.statusUpdatedAt > 0
                                  ? app.statusUpdatedAt
                                  : app.timeStamp,
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              canCancel
                  ? AppHeaderActionButton(
                      onTap: () => _showCancelDialog(app.jobDocID),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Color(0xFFB91C1C),
                        size: 18,
                      ),
                    )
                  : AppHeaderActionButton(
                      child: Icon(
                        _statusIcon(status),
                        color: _statusColor(status),
                        size: 18,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackLogo() {
    return Container(
      color: Colors.grey.withAlpha(30),
      child: const Icon(
        CupertinoIcons.building_2_fill,
        color: Colors.grey,
        size: 24,
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'reviewing':
        bgColor = Colors.blue.withAlpha(25);
        textColor = Colors.blue;
        break;
      case 'accepted':
        bgColor = Colors.green.withAlpha(25);
        textColor = Colors.green;
        break;
      case 'rejected':
        bgColor = Colors.red.withAlpha(25);
        textColor = Colors.red;
        break;
      default:
        bgColor = Colors.orange.withAlpha(25);
        textColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        JobApplicationModel.statusText(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: "MontserratMedium",
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reviewing':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return const Color(0xFFB91C1C);
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return CupertinoIcons.check_mark_circled_solid;
      case 'rejected':
        return CupertinoIcons.xmark_circle_fill;
      case 'reviewing':
        return CupertinoIcons.clock_fill;
      default:
        return CupertinoIcons.xmark;
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  void _showCancelDialog(String jobDocID) {
    Get.dialog(
      AlertDialog(
        title: Text(
          "pasaj.job_finder.cancel_apply_title".tr,
          style: const TextStyle(fontFamily: "MontserratBold", fontSize: 16),
        ),
        content: Text(
          "pasaj.job_finder.cancel_apply_body".tr,
          style: const TextStyle(fontFamily: "MontserratMedium", fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "common.cancel".tr,
              style: const TextStyle(fontFamily: "MontserratMedium"),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelApplication(jobDocID);
            },
            child: Text(
              "common.remove".tr,
              style: const TextStyle(
                color: Colors.red,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
