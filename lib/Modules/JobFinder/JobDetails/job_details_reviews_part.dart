part of 'job_details.dart';

extension JobDetailsReviewsPart on JobDetails {
  void _showJobReviewBottomSheet(JobDetailsController controller) {
    final currentUserId = _currentUid;
    final existingReview = controller.reviews
        .where((review) => review.userID == currentUserId)
        .cast<dynamic>()
        .firstOrNull;
    int selectedRating = existingReview?.rating ?? 5;
    final textController = TextEditingController(
      text: existingReview?.comment ?? '',
    );
    bool isSubmitting = false;

    Get.bottomSheet(
      SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "pasaj.market.rate".tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => selectedRating = star),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              star <= selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 28,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "pasaj.market.review_comment_hint".tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                setState(() => isSubmitting = true);
                                final success = await controller.submitReview(
                                  rating: selectedRating,
                                  comment: textController.text,
                                );
                                if (context.mounted) {
                                  setState(() => isSubmitting = false);
                                }
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          disabledBackgroundColor: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                "common.save".tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ignore: unused_element
  Widget _buildReviewsSection(JobDetailsController controller) {
    return Obx(() {
      final currentUserId = _currentUid;
      final canReview = currentUserId.isNotEmpty &&
          currentUserId != controller.model.value.userID;
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
              Text("pasaj.market.reviews".tr, style: TextStyles.bold16Black),
              if (canReview)
                GestureDetector(
                  onTap: () => _showJobReviewBottomSheet(controller),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "pasaj.market.rate".tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.reviews.isEmpty)
            Text(
              "pasaj.market.no_reviews".tr,
              style: TextStyles.tutoringLocation,
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
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
                          child: Text("$star", style: TextStyles.bold15Black),
                        ),
                        4.pw,
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        8.pw,
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(
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
            const SizedBox(height: 8),
            ...controller.reviews.map((review) {
              final user = controller.reviewUsers[review.userID] ?? {};
              final name = (user['nickname'] ??
                      user['username'] ??
                      user['displayName'] ??
                      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
                  .toString()
                  .trim();
              final avatar = (user['avatarUrl'] ?? '').toString().trim();
              final isOwn = currentUserId == review.userID;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                            child: avatar.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatar,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const DefaultAvatar(radius: 14),
                                  )
                                : const DefaultAvatar(radius: 14),
                          ),
                        ),
                        8.pw,
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isNotEmpty ? name : "common.user".tr,
                                  style: TextStyles.bold15Black,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                            onTap: () =>
                                controller.deleteReview(review.reviewID),
                            child: const Icon(
                              CupertinoIcons.trash,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (review.comment.trim().isNotEmpty) ...[
                      6.ph,
                      Text(
                        review.comment.trim(),
                        style: TextStyles.medium15Black,
                      ),
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

  Widget _buildSimilarSection(JobDetailsController controller) {
    return Obx(() {
      final items = controller.list
          .where((doc) => doc.docID != controller.model.value.docID)
          .toList();
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("pasaj.market.related_listings".tr, style: TextStyles.bold16Black),
          8.ph,
          SizedBox(
            height: (Get.height * 0.30).clamp(206.0, 236.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final title = item.ilanBasligi.isNotEmpty
                    ? item.ilanBasligi
                    : item.meslek;
                return GestureDetector(
                  onTap: () => Get.off(() => JobDetails(model: item)),
                  child: Container(
                    width: (Get.width * 0.43).clamp(142.0, 166.0),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: SizedBox(
                            height: (Get.height * 0.135).clamp(96.0, 112.0),
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl: item.logo,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(CupertinoIcons.photo),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyles.bold15Black,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                2.ph,
                                Text(
                                  item.brand,
                                  style: TextStyles.tutoringBranch,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                2.ph,
                                Text(
                                  "${item.city}, ${item.town}",
                                  style: TextStyles.tutoringLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "pasaj.market.inspect".tr,
                                    style: const TextStyle(
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
}
