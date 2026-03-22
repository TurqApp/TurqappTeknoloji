part of 'tests_grid.dart';

extension TestsGridBodyPart on _TestsGridState {
  Widget _buildBody(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.handleTestAction(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tests.type_test'.trParams({
                    'type': model.testTuru,
                  }),
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                GestureDetector(
                  onTap: controller.toggleFavorite,
                  child: Obx(
                    () => Icon(
                      controller.isFavorite.value
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      color: controller.isFavorite.value
                          ? Colors.orange
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              model.aciklama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'MontserratMedium',
              ),
            ),
            SizedBox(height: 7),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'tests.level_easy'.tr,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formattedViewMetric(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: SvgPicture.asset(
                          'icons/statsyeni.svg',
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (model.userID == _currentUserId) _buildOwnerIdRow(context),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerIdRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => controller.copyTestId(context),
            child: Text(
              'ID: ${model.docID}',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.copyTestId(context),
            child: Icon(
              CupertinoIcons.doc_on_doc,
              color: Colors.pink,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.navigateToTestSolve(context),
      child: Padding(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 7),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.pink,
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          child: Text(
            'tests.start_now'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ),
    );
  }

  String _formattedViewMetric() {
    final weighted = controller.totalYanit.value * 9;
    if (weighted / 1000000 > 1) {
      return '${(weighted / 1000000).toStringAsFixed(2)}M';
    }
    if (weighted / 1000 > 1) {
      return '${(weighted / 1000).toStringAsFixed(1)}B';
    }
    return weighted.toString();
  }
}
