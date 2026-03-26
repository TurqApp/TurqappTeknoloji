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

  void _refreshQuotedSourceProfileFuture() {
    final sourceUserId = widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.originalUserID.trim();
    _quotedSourceProfileUserId = sourceUserId;
    if (sourceUserId.isEmpty) {
      _quotedSourceProfileFuture = null;
      return;
    }

    final profileCache = UserProfileCacheService.ensure();
    _quotedSourceProfileFuture = profileCache.getProfile(
      sourceUserId,
      preferCache: true,
    );
  }

  Widget _buildClassicInlineCaption({
    required String nickname,
    required String text,
  }) {
    const nameStyle = TextStyle(
      color: Color(0xFF20252B),
      fontSize: 14,
      fontFamily: 'MontserratBold',
      height: 1.35,
    );
    const bodyStyle = TextStyle(
      color: Color(0xFF20252B),
      fontSize: 13,
      fontFamily: 'Montserrat',
      height: 1.35,
    );
    const moreStyle = TextStyle(
      color: Color(0xFF6E7680),
      fontSize: 14,
      fontFamily: 'Montserrat',
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
    const bodyStyle = TextStyle(
      color: Color(0xFF8A9199),
      fontSize: 13,
      fontFamily: 'Montserrat',
      height: 1.35,
    );
    const moreStyle = TextStyle(
      color: Color(0xFF8A9199),
      fontSize: 13,
      fontFamily: 'Montserrat',
      height: 1.35,
    );
    const nickStyle = TextStyle(
      color: Color(0xFF4B5561),
      fontSize: 13,
      fontFamily: 'MontserratBold',
      height: 1.35,
    );

    String resolveSourceNickname(Map<String, dynamic>? profile) {
      final raw = (profile?['nickname'] ??
              profile?['displayName'] ??
              profile?['username'] ??
              '')
          .toString()
          .trim();
      if (raw.isNotEmpty) return raw;
      final fallback =
          widget.model.quotedSourceUserID.trim() == widget.model.userID
              ? (controller.username.value.trim().isNotEmpty
                  ? controller.username.value.trim()
                  : controller.nickname.value.trim())
              : '';
      return fallback;
    }

    final future = sourceUserId.trim() == _quotedSourceProfileUserId
        ? _quotedSourceProfileFuture
        : null;

    return FutureBuilder<Map<String, dynamic>?>(
      future: future,
      builder: (context, snapshot) {
        final sourceNickname = resolveSourceNickname(snapshot.data);
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
        : (widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final publishedAt = DateTime.fromMillisecondsSinceEpoch(sourceMs.toInt());
    final now = DateTime.now();
    final diff = now.difference(publishedAt);

    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes.clamp(1, 59);
      return '$minutes dakika önce';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    }

    const months = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final monthLabel = months[publishedAt.month - 1];
    if (publishedAt.year == now.year) {
      return '${publishedAt.day} $monthLabel';
    }
    return '${publishedAt.day} $monthLabel ${publishedAt.year}';
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
            _buildClassicQuotedText(
              quotedText,
              sourceUserId: widget.model.quotedSourceUserID.trim(),
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
              style: const TextStyle(
                color: Color(0xFF8A9199),
                fontSize: 12,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          if (widget.model.poll.isNotEmpty) buildPollCard(),
        ],
      ),
    );
  }
}
