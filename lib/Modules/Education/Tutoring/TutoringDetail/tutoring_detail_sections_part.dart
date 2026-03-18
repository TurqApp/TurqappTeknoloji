part of 'tutoring_detail.dart';

extension TutoringDetailSectionsPart on TutoringDetail {
  Widget _buildSimilarSection(TutoringDetailController controller) {
    return Obx(() {
      if (controller.similarList.isEmpty) return SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Benzer İlanlar", style: TextStyles.bold16Black),
          8.ph,
          SizedBox(
            height: (Get.height * 0.30).clamp(206.0, 236.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.similarList.length,
              itemBuilder: (context, index) {
                final item = controller.similarList[index];
                final user = controller.similarUsers[item.userID] ?? {};
                final name = (user['nickname'] ??
                        user['username'] ??
                        user['displayName'] ??
                        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
                    .toString()
                    .trim();
                return GestureDetector(
                  onTap: () {
                    Get.off(() => TutoringDetail(), arguments: item);
                  },
                  child: Container(
                    width: (Get.width * 0.43).clamp(142.0, 166.0),
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                          child: SizedBox(
                            height: (Get.height * 0.135).clamp(96.0, 112.0),
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl:
                                  item.imgs != null && item.imgs!.isNotEmpty
                                      ? item.imgs!.first
                                      : '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(CupertinoIcons.photo),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.baslik,
                                  style: TextStyles.bold15Black,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                2.ph,
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "$name ",
                                        style: TextStyles.tutoringBranch,
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: RozetContent(
                                          size: 12,
                                          userID: item.userID,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                2.ph,
                                Text(
                                  "${item.fiyat} ₺",
                                  style: TextStyles.bold15Black,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "İlana Git",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget pullDownMenu(TutoringDetailController controller) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(
              () => ReportUser(
                userID: controller.tutoring.value.userID,
                postID: controller.tutoring.value.docID,
                commentID: "",
              ),
            );
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
