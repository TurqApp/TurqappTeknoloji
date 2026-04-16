part of 'classic_content.dart';

extension _ClassicContentQuotePart on _ClassicContentState {
  Future<void> _openMentionProfile(String mention) async {
    final targetUid =
        await UsernameLookupRepository.ensure().findUidForHandle(mention) ?? '';
    final currentUid = _currentUid;
    if (targetUid.isNotEmpty && targetUid != currentUid) {
      _suspendClassicFeedForRoute();
      await Get.to(() => SocialProfile(userID: targetUid));
      _restoreClassicFeedCenter();
    }
  }

  void _refreshQuotedSourceFuture() {
    final sourceUserId = widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.originalUserID.trim();
    final sourcePostId = widget.model.originalPostID.trim();

    _quotedSourceFutureUserId = sourceUserId;
    _quotedSourceFuturePostId = sourcePostId;
    if (sourceUserId.isEmpty) {
      _quotedSourceFuture = null;
      return;
    }

    final profileCache = ensureUserProfileCacheService();
    final postRepository = PostRepository.ensure();
    _quotedSourceFuture = Future.wait<dynamic>([
      profileCache.getProfile(
        sourceUserId,
        preferCache: true,
        cacheOnly: false,
      ),
      if (sourcePostId.isNotEmpty)
        postRepository.fetchPostCardsByIds([sourcePostId], preferCache: true)
      else
        Future.value(null),
    ]);
  }

  Widget _buildClassicInlineCaption({
    required String nickname,
    required String text,
  }) {
    final captionFontSize = _classicPostCaptionFontSize;
    final nameStyle = _classicPostCaptionStyle.copyWith(
      color: const Color(0xFF20252B),
      fontSize: captionFontSize,
      fontFamily: 'MontserratBold',
      height: 1.35,
    );
    final bodyStyle = _classicPostCaptionStyle.copyWith(
      color: const Color(0xFF20252B),
      fontSize: captionFontSize,
      height: 1.35,
    );
    final moreStyle = _classicPostCaptionStyle.copyWith(
      color: const Color(0xFF6E7680),
      fontSize: captionFontSize,
      height: 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          children: [
            TextSpan(text: nickname, style: nameStyle),
            const TextSpan(text: '  '),
            ...buildClickableTextControllerSpans(
              text: text,
              plainStyle: bodyStyle,
              urlStyle: bodyStyle.copyWith(color: Colors.blue),
              hashtagStyle: bodyStyle.copyWith(color: Colors.blue),
              mentionStyle: bodyStyle.copyWith(color: Colors.blue),
              onUrlTap: (url) => RedirectionLink().goToLink(url),
              onHashtagTap: (tag) {
                if (tag.trim().isEmpty) return;
                _suspendClassicFeedForRoute();
                Get.to(() => TagPosts(tag: tag.trim()))?.then((_) {
                  _restoreClassicFeedCenter();
                });
              },
              onMentionTap: (mention) {
                unawaited(_openMentionProfile(mention));
              },
            ),
          ],
        );

        final painter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: constraints.maxWidth);

        final exceeds = painter.didExceedMaxLines;

        Widget content = RichText(
          text: span,
          maxLines: _isCaptionExpanded ? null : 2,
          overflow:
              _isCaptionExpanded ? TextOverflow.visible : TextOverflow.clip,
        );

        if (!_isCaptionExpanded && exceeds) {
          content = Stack(
            children: [
              RichText(
                text: span,
                maxLines: 2,
                overflow: TextOverflow.clip,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('common.show_more'.tr, style: moreStyle),
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap:
              exceeds ? () => _setCaptionExpanded(!_isCaptionExpanded) : null,
          child: content,
        );
      },
    );
  }

  Widget _buildClassicQuotedText(
    String text, {
    required String sourceUserId,
  }) {
    final captionFontSize = _classicPostCaptionFontSize;
    final bodyStyle = _classicPostCaptionStyle.copyWith(
      color: const Color(0xFF8A9199),
      fontSize: captionFontSize,
      height: 1.35,
    );
    final moreStyle = _classicPostCaptionStyle.copyWith(
      color: const Color(0xFF8A9199),
      fontSize: captionFontSize,
      height: 1.35,
    );
    final nickStyle = _classicPostCaptionStyle.copyWith(
      color: const Color(0xFF4B5561),
      fontSize: captionFontSize,
      fontFamily: 'MontserratBold',
      height: 1.35,
    );

    String resolveSourceNickname(
      Map<String, dynamic>? profile,
      Map<String, dynamic>? sourcePostData,
    ) {
      String firstNonEmpty(List<dynamic> values) {
        for (final value in values) {
          final text = (value ?? '').toString().trim();
          if (text.isNotEmpty) return text;
        }
        return '';
      }

      final raw = firstNonEmpty([
        widget.model.quotedSourceUsername,
        profile?['username'],
        sourcePostData?['username'],
        sourcePostData?['authorNickname'],
        profile?['nickname'],
        profile?['displayName'],
      ]);
      if (raw.isNotEmpty) return raw;
      final fallback =
          widget.model.quotedSourceUserID.trim() == widget.model.userID
              ? (controller.username.value.trim().isNotEmpty
                  ? controller.username.value.trim()
                  : controller.nickname.value.trim())
              : '';
      return fallback;
    }

    final future = sourceUserId.trim() == _quotedSourceFutureUserId
        ? _quotedSourceFuture
        : null;

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final profile = (snapshot.data != null && snapshot.data!.isNotEmpty
                ? snapshot.data!.first
                : null) as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final sourcePostMap = snapshot.data != null && snapshot.data!.length > 1
            ? snapshot.data![1] as Map<String, PostsModel>?
            : null;
        final sourcePostData =
            sourcePostMap?[_quotedSourceFuturePostId]?.toMap() ??
                const <String, dynamic>{};
        final sourceNickname = resolveSourceNickname(profile, sourcePostData);
        final quotedSpan = <InlineSpan>[
          if (sourceNickname.isNotEmpty)
            TextSpan(text: '$sourceNickname ', style: nickStyle),
          TextSpan(text: text, style: bodyStyle),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(children: quotedSpan),
              textDirection: TextDirection.ltr,
              maxLines: 2,
            )..layout(maxWidth: constraints.maxWidth);

            final exceeds = painter.didExceedMaxLines;

            Widget content = RichText(
              text: TextSpan(children: quotedSpan),
              maxLines: _isQuoteExpanded ? null : 2,
              overflow:
                  _isQuoteExpanded ? TextOverflow.visible : TextOverflow.clip,
            );

            if (!_isQuoteExpanded && exceeds) {
              content = Stack(
                children: [
                  RichText(
                    text: TextSpan(children: quotedSpan),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('common.show_more'.tr, style: moreStyle),
                    ),
                  ),
                ],
              );
            }

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap:
                  exceeds ? () => _setQuoteExpanded(!_isQuoteExpanded) : null,
              child: content,
            );
          },
        );
      },
    );
  }

  Widget _buildClassicActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 15, right: 15),
      child: Row(
        children: [
          _buildClassicQuoteActionSlot(
            commentButton(context),
            offsetX: -5,
          ),
          _buildClassicQuoteActionSlot(
            likeButton(),
          ),
          _buildClassicQuoteActionSlot(
            reshareButton(),
          ),
          _buildClassicQuoteActionSlot(
            statButton(),
          ),
          _buildClassicQuoteActionSlot(
            saveButton(),
          ),
          _buildClassicQuoteActionSlot(
            sendButton(),
            offsetX: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildClassicQuoteActionSlot(
    Widget child, {
    double offsetX = 0,
  }) {
    return Expanded(
      child: Transform.translate(
        offset: Offset(offsetX, 0),
        child: Center(child: child),
      ),
    );
  }

  String _buildClassicBottomTimeLabel() {
    final sourceMs = controller.editTime.value != 0
        ? controller.editTime.value
        : widget.model.timeStamp;
    return timeAgoMetin(sourceMs);
  }

  Future<void> _openQuotedOriginalPost() async {
    final originalPostId = widget.model.originalPostID.trim();
    if (originalPostId.isEmpty) {
      AppSnackbar('common.info'.tr, 'post.source_unavailable'.tr);
      return;
    }

    try {
      final model = await PostRepository.ensure().fetchPostById(
        originalPostId,
        preferCache: true,
      );
      if (model == null) {
        AppSnackbar('common.info'.tr, 'post.source_unavailable'.tr);
        return;
      }
      if (model.deletedPost) {
        AppSnackbar('common.info'.tr, 'post.source_deleted'.tr);
        return;
      }

      _suspendClassicFeedForRoute();
      try {
        playbackRuntimeService.pauseAll(force: true);
      } catch (_) {}
      try {
        agendaController.pauseAll.value = false;
      } catch (_) {}

      if (model.floodCount > 1) {
        await Get.to(() => FloodListing(
              mainModel: model,
              hostSurface: widget.floodHostSurface,
            ));
      } else {
        await Get.to(() => SinglePost(model: model, showComments: false));
      }
      _restoreClassicFeedCenter();
    } catch (_) {
      AppSnackbar('common.info'.tr, 'post.source_unavailable'.tr);
    }
  }

  Widget _buildClassicMetaSection() {
    final caption =
        _ClassicContentState._ctaNavigationService.sanitizeCaptionText(
      widget.model.metin,
      meta: widget.model.reshareMap,
    );
    final hasCaption = caption.isNotEmpty;
    final quotedText = widget.model.quotedOriginalText.trim();
    final hasQuotedText = widget.model.quotedPost && quotedText.isNotEmpty;
    final captionNickname = controller.username.value.trim().isNotEmpty
        ? controller.username.value.trim()
        : controller.nickname.value.trim();
    final displayTime = _buildClassicBottomTimeLabel();

    if (!widget.isReshared &&
        !hasQuotedText &&
        !hasCaption &&
        widget.model.poll.isEmpty &&
        displayTime.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasQuotedText)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openQuotedOriginalPost,
              child: _buildClassicQuotedText(
                quotedText,
                sourceUserId: widget.model.quotedSourceUserID.trim(),
              ),
            ),
          if (hasQuotedText && hasCaption) const SizedBox(height: 4),
          if (hasCaption)
            _buildClassicInlineCaption(
              nickname: captionNickname,
              text: caption,
            ),
          Padding(
            padding: EdgeInsets.only(
              top: (hasQuotedText || hasCaption) ? 6 : 0,
            ),
            child: Text(
              displayTime,
              style: _classicPostMetaStyle.copyWith(
                color: const Color(0xFF8A9199),
              ),
            ),
          ),
          if (widget.model.poll.isNotEmpty) buildPollCard(),
        ],
      ),
    );
  }
}
