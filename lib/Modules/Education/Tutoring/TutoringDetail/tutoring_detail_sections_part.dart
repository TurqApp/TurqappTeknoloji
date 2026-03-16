part of 'tutoring_detail.dart';

extension TutoringDetailSectionsPart on TutoringDetail {
  Widget _buildReviewsSection(
      TutoringDetailController controller, String? currentUserId) {
    return Obx(() {
      final canReview = currentUserId != null &&
          currentUserId != controller.tutoring.value.userID;
      final totalReviews = controller.reviews.length;
      final ratingCounts = <int, int>{
        for (var star = 1; star <= 5; star++) star: 0,
      };
      for (final review in controller.reviews) {
        final rating = review.rating.clamp(1, 5);
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Değerlendirmeler", style: TextStyles.bold16Black),
              if (canReview)
                GestureDetector(
                  onTap: () {
                    showTutoringReviewBottomSheet(
                      docID: controller.tutoring.value.docID,
                      controller: controller,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Değerlendir",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          8.ph,
          if (controller.reviews.isEmpty)
            Text(
              "Henüz değerlendirme yok.",
              style: TextStyles.tutoringLocation,
            )
          else ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  final count = ratingCounts[star] ?? 0;
                  final percent =
                      totalReviews == 0 ? 0.0 : count / totalReviews;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            "$star",
                            style: TextStyles.bold15Black,
                          ),
                        ),
                        4.pw,
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        8.pw,
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        8.pw,
                        SizedBox(
                          width: 42,
                          child: Text(
                            "%${(percent * 100).round()}",
                            textAlign: TextAlign.right,
                            style: TextStyles.tutoringLocation,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            8.ph,
            ...controller.reviews.map((review) {
              final user = controller.reviewUsers[review.userID] ?? {};
              final name = (user['nickname'] ??
                      user['username'] ??
                      user['displayName'] ??
                      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
                  .toString()
                  .trim();
              final avatarUrl = (user['avatarUrl'] ?? '').toString().trim();
              final isOwn = currentUserId == review.userID;
              final shouldHideReviewCard = name.isEmpty &&
                  avatarUrl.isEmpty &&
                  review.comment.trim().isEmpty &&
                  !isOwn;
              if (shouldHideReviewCard) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Icon(Icons.person, size: 16),
                            ),
                          ),
                        ),
                        8.pw,
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child:
                                    Text(name, style: TextStyles.bold15Black),
                              ),
                              4.pw,
                              RozetContent(size: 12, userID: review.userID),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        if (isOwn) ...[
                          4.pw,
                          GestureDetector(
                            onTap: () {
                              controller.deleteReview(
                                controller.tutoring.value.docID,
                                review.reviewID,
                              );
                            },
                            child: Icon(CupertinoIcons.trash,
                                size: 16, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      6.ph,
                      Text(review.comment, style: TextStyles.medium15Black),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      );
    });
  }

  Widget _buildSimilarSection(TutoringDetailController controller) {
    return Obx(() {
      if (controller.similarList.isEmpty) return SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Benzer İlanlar", style: TextStyles.bold16Black),
          8.ph,
          SizedBox(
            height: (Get.height * 0.28).clamp(188.0, 218.0),
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
                    width: (Get.width * 0.42).clamp(136.0, 160.0),
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
                            height: (Get.height * 0.125).clamp(84.0, 100.0),
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
