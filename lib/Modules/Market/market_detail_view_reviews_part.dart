part of 'market_detail_view.dart';

extension _MarketDetailViewReviewsPart on _MarketDetailViewState {
  Widget _performBuildReviewsSection() {
    final canReview = !_isOwner;
    final currentUserId = _currentUserId;
    final existingReview = _reviews
        .where((review) => review.userId == currentUserId)
        .cast<MarketReviewModel?>()
        .firstOrNull;
    final totalReviews = _reviews.length;
    final ratingCounts = <int, int>{
      for (var star = 1; star <= 5; star++) star: 0,
    };
    for (final review in _reviews) {
      final rating = review.rating.clamp(1, 5);
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'pasaj.market.reviews'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
            if (canReview)
              GestureDetector(
                onTap: () => _showReviewSheet(existingReview: existingReview),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    existingReview == null
                        ? 'pasaj.market.rate'.tr
                        : 'pasaj.market.review_edit'.tr,
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
        if (_isLoadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CupertinoActivityIndicator(),
          )
        else if (_reviews.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => const Padding(
                    padding: EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.star_border_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'pasaj.market.no_reviews'.tr,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ],
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = ratingCounts[star] ?? 0;
                final percent = totalReviews == 0 ? 0.0 : count / totalReviews;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(
                          '$star',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
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
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '%${(percent * 100).round()}',
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
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          ..._reviews.map(_buildReviewCard),
        ],
      ],
    );
  }

  Widget _performBuildReviewCard(MarketReviewModel review) {
    final currentUserId = _currentUserId;
    final user = _reviewUsers[review.userId] ?? const <String, dynamic>{};
    final name = (user['nickname'] ??
            user['username'] ??
            user['displayName'] ??
            user['fullName'] ??
            '')
        .toString()
        .trim();
    final avatarUrl = (user['avatarUrl'] ?? '').toString().trim();
    final rozet = (user['rozet'] ?? '').toString().trim();
    final isOwn = currentUserId == review.userId;
    final shouldHide =
        name.isEmpty && avatarUrl.isEmpty && review.comment.isEmpty;
    if (shouldHide) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 16, color: Colors.black54)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      name.isEmpty ? 'Kullanici' : name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    if (rozet.isNotEmpty)
                      RozetContent(
                        size: 12,
                        userID: review.userId,
                        rozetValue: rozet,
                        leftSpacing: 1,
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
              if (isOwn) ...[
                GestureDetector(
                  onTap: () => _showReviewSheet(existingReview: review),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _deleteReview(review.reviewId),
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
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _performLoadReviews() async {
    if (!mounted) return;
    _updateViewState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews =
          await _MarketDetailViewState._reviewService.fetchReviews(item.id);
      final userIds =
          reviews.map((e) => e.userId).toSet().toList(growable: false);
      final summaries = userIds.isEmpty
          ? const <String, dynamic>{}
          : await _MarketDetailViewState._userRepository.getUsers(userIds);
      _updateViewState(() {
        _reviews = reviews;
        _reviewUsers = {
          for (final entry in summaries.entries) entry.key: entry.value.toMap(),
        };
      });
    } catch (_) {
      _updateViewState(() {
        _reviews = const <MarketReviewModel>[];
        _reviewUsers = const <String, Map<String, dynamic>>{};
      });
    } finally {
      _updateViewState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _performShowReviewSheet({
    MarketReviewModel? existingReview,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId.isEmpty) {
      AppSnackbar(
        'common.info'.tr,
        'pasaj.market.sign_in_to_review'.tr,
      );
      return;
    }
    final selectedRating = ValueNotifier<int>(existingReview?.rating ?? 5);
    final commentController = TextEditingController();
    commentController.text = existingReview?.comment ?? '';
    final isSubmitting = ValueNotifier<bool>(false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: isSubmitting,
            builder: (context, submitting, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'pasaj.market.rate'.tr,
                    style: const TextStyle(
                      fontFamily: 'MontserratBold',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: selectedRating,
                      builder: (context, rating, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => selectedRating.value = index + 1,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 28,
                                  color: index < rating
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration:
                        _inputDecoration('pasaj.market.review_comment_hint'.tr),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (selectedRating.value == 0) {
                                AppSnackbar(
                                  'common.error'.tr,
                                  'pasaj.market.select_rating'.tr,
                                );
                                return;
                              }
                              isSubmitting.value = true;
                              try {
                                await _MarketDetailViewState._reviewService
                                    .submitReview(
                                  itemId: item.id,
                                  ownerId: item.userId,
                                  rating: selectedRating.value,
                                  comment: commentController.text.trim(),
                                );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                                await _loadReviews();
                                AppSnackbar(
                                  'common.success'.tr,
                                  existingReview == null
                                      ? 'pasaj.market.review_saved'.tr
                                      : 'pasaj.market.review_updated'.tr,
                                );
                              } catch (e) {
                                final message = e.toString().contains(
                                          'own_item_review_not_allowed',
                                        )
                                    ? 'pasaj.market.review_own_forbidden'.tr
                                    : 'pasaj.market.review_failed'.tr;
                                AppSnackbar('common.error'.tr, message);
                              } finally {
                                isSubmitting.value = false;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'common.save'.tr,
                              style: const TextStyle(
                                fontFamily: 'MontserratBold',
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _performDeleteReview(String reviewId) async {
    try {
      await _MarketDetailViewState._reviewService.deleteReview(
        itemId: item.id,
        reviewId: reviewId,
      );
      await _loadReviews();
      AppSnackbar('common.success'.tr, 'pasaj.market.review_deleted'.tr);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'pasaj.market.review_delete_failed'.tr);
    }
  }
}
