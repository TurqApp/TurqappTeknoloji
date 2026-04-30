part of 'job_details.dart';

extension JobDetailsMetaPart on _JobDetailsState {
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
                  ? CacheFirstNetworkImage(
                      imageUrl: _buildStaticMapUrl(controller.model.value),
                      cacheManager: TurqImageCacheManager.instance,
                      fit: BoxFit.cover,
                      memCacheWidth: 1300,
                      memCacheHeight: 720,
                      fallback: Container(
                        color: const Color(0xFFF3F5F7),
                        alignment: Alignment.center,
                        child: Text(
                          'pasaj.job_finder.map_load_failed'.tr,
                          style: const TextStyle(
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
                                ? 'pasaj.job_finder.open_in_maps'.tr
                                : 'pasaj.market.location_missing'.tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          if (hasLocation)
                            Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'pasaj.job_finder.open_maps_help'.tr,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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

  Widget pullDownMenu() {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            const ReportUserNavigationService().openReportUser(
              userId: controller.model.value.userID,
              postId: controller.model.value.docID,
            );
          },
          title: 'pasaj.market.report_listing'.tr,
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => AppHeaderActionButton(
        onTap: showMenu,
        size: 36,
        child: Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
          size: 18,
        ),
      ),
    );
  }
}
