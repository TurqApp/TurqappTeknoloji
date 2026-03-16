part of 'job_details.dart';

extension JobDetailsMetaPart on JobDetails {
  bool _hasValidCoordinates(JobModel job) {
    if (!job.lat.isFinite || !job.long.isFinite) return false;
    if (job.lat == 0 || job.long == 0) return false;
    if (job.lat < -90 || job.lat > 90) return false;
    if (job.long < -180 || job.long > 180) return false;
    return true;
  }

  String _buildStaticMapUrl(JobModel job) {
    return Uri.https(
      'static-maps.yandex.ru',
      '/1.x/',
      {
        'll': '${job.long},${job.lat}',
        'zoom': '15',
        'size': '650,360',
        'l': 'map',
        'lang': 'tr_TR',
        'pt': '${job.long},${job.lat},pm2rdm',
      },
    ).toString();
  }

  Widget _buildLocationPreview(BuildContext context) {
    final hasLocation = _hasValidCoordinates(controller.model.value);

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: GestureDetector(
            onTap: hasLocation
                ? () {
                    controller.showMapsSheet(
                      controller.model.value.lat,
                      controller.model.value.long,
                    );
                  }
                : null,
            child: SizedBox(
              width: double.infinity,
              height: (MediaQuery.of(context).size.height * 0.28)
                  .clamp(180.0, 220.0),
              child: hasLocation
                  ? CachedNetworkImage(
                      imageUrl: _buildStaticMapUrl(controller.model.value),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF3F5F7),
                        alignment: Alignment.center,
                        child: const Text(
                          'Harita yüklenemedi',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF3F5F7),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasLocation
                                ? CupertinoIcons.location_solid
                                : CupertinoIcons.location_slash,
                            color: hasLocation ? Colors.red : Colors.grey,
                            size: 34,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hasLocation
                                ? 'Haritada Aç'
                                : 'Konum bilgisi bulunamadı',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          if (hasLocation)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Apple Haritalar veya diğer uygulamalarda aç',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (hasLocation)
          const Icon(
            CupertinoIcons.location_solid,
            color: Colors.red,
            size: 30,
          ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    );
  }

  Widget pullDownMenu() {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(() => ReportUser(
                  userID: controller.model.value.userID,
                  postID: controller.model.value.docID,
                  commentID: "",
                ));
          },
          title: 'İlanı Bildir',
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => AppHeaderActionButton(
        onTap: showMenu,
        child: Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }
}
