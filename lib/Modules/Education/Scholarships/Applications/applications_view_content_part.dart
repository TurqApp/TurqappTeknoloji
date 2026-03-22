part of 'applications_view.dart';

extension _ApplicationsViewContentPart on _ApplicationsViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'scholarship.my_applications_title'.tr),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => controller.applications.isEmpty
                                    ? Center(
                                        child: EmptyRow(
                                          text:
                                              'scholarship.no_user_applications'
                                                  .tr,
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            controller.applications.length,
                                        itemBuilder: (context, index) {
                                          final application =
                                              controller.applications[index];
                                          return _buildApplicationCard(
                                            context,
                                            application,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    Map<String, dynamic> application,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = (screenWidth * 0.31).clamp(96.0, 120.0);
    final thumbnailHeight = (thumbnailWidth * 0.75).clamp(72.0, 90.0);

    return GestureDetector(
      onTap: () => _openApplicationDetail(application),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildThumbnail(
              application: application,
              width: thumbnailWidth,
              height: thumbnailHeight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'scholarship.applications_suffix'.trParams({
                            'title': application['title'],
                          }),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            title: 'scholarship.withdraw_application'.tr,
                            icon: CupertinoIcons.restart,
                            onTap: () =>
                                _showWithdrawSheet(context, application),
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.black,
                          ),
                          onPressed: showMenu,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    application['nickname'],
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  Text(
                    application['desc'],
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail({
    required Map<String, dynamic> application,
    required double width,
    required double height,
  }) {
    final imageUrl = (application['img'] ?? '').toString();
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/images/placeholder.webp',
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  'assets/images/placeholder.webp',
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                ),
        ],
      ),
    );
  }
}
