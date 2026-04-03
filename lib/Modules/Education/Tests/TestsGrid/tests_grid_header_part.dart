part of 'tests_grid.dart';

extension TestsGridHeaderPart on _TestsGridState {
  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildPreview(context),
          _buildBody(context),
          if (model.userID != _currentUserId) _buildStartButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 5),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.navigateToProfile(context),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: SizedBox(
                        width: 23,
                        height: 23,
                        child: Obx(
                          () => CachedUserAvatar(
                            userId: model.userID,
                            imageUrl: controller.avatarUrl.value,
                            radius: 11.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Obx(
                        () => Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.nickname.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontFamily: 'MontserratBold',
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            RozetContent(size: 12, userID: model.userID),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (model.userID != _currentUserId)
              GestureDetector(
                onTap: () => controller.showReportModal(context),
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.handleTestAction(context),
      child: AspectRatio(
        aspectRatio: 1,
        child: model.img.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: model.img,
                fit: BoxFit.cover,
              )
            : Center(child: CupertinoActivityIndicator()),
      ),
    );
  }
}
