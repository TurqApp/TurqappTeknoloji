part of 'agenda_content.dart';

extension AgendaContentBodyWidgetsPart on _AgendaContentState {
  Widget buildPollCard() {
    return Obx(() {
      final model = controller.currentModel.value ?? widget.model;
      final poll = model.poll;
      if (poll.isEmpty) return const SizedBox.shrink();
      final options = (poll['options'] is List) ? poll['options'] as List : [];
      if (options.isEmpty) return const SizedBox.shrink();

      final totalVotes =
          (poll['totalVotes'] is num) ? poll['totalVotes'] as num : 0;
      final uid = controller.userService.effectiveUserId;
      final userVotes = poll['userVotes'] is Map
          ? Map<String, dynamic>.from(poll['userVotes'])
          : <String, dynamic>{};
      final userVoteRaw = userVotes[uid];
      final int? userVote = userVoteRaw is num
          ? userVoteRaw.toInt()
          : int.tryParse('${userVoteRaw ?? ''}');
      final effectiveUserVote = userVote ?? controller.localPollSelection.value;

      final createdAt = (poll['createdDate'] ?? model.timeStamp) as num;
      final durationHours = (poll['durationHours'] ?? 24) as num;
      final expiresAt =
          createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
      final expired = DateTime.now().millisecondsSinceEpoch > expiresAt;
      final canVote = !expired && effectiveUserVote == null;
      final showResults = effectiveUserVote != null || expired;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(options.length, (i) {
              final text = (options[i]['text'] ?? '').toString();
              final votes = (options[i]['votes'] ?? 0) as num;
              final pct = totalVotes > 0 ? (votes / totalVotes) : 0.0;
              final label = '${String.fromCharCode(65 + i)}) ';
              final isSelected = effectiveUserVote == i;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canVote ? () => controller.votePoll(i) : null,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue.withAlpha(18) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected ? Colors.blueAccent : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$label$text',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (showResults)
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Toplam ${totalVotes.toInt()} oy',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: "MontserratMedium",
                  ),
                ),
                const Spacer(),
                Text(
                  _pollRemainingLabel(
                    expired: expired,
                    expiresAtMs: expiresAt,
                  ),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget buildUploadIndicator() {
    final uploadService = UploadQueueService.ensure();

    return Obx(() {
      QueuedUpload? item;
      for (final q in uploadService.queue) {
        if (q.id == widget.model.docID &&
            (q.status == UploadStatus.pending ||
                q.status == UploadStatus.uploading)) {
          item = q;
          break;
        }
      }

      double? progress;
      if (item != null) {
        progress = item.progress;
      } else {
        final hasVideo = widget.model.hasPlayableVideo ||
            widget.model.video.trim().isNotEmpty ||
            widget.model.hlsMasterUrl.trim().isNotEmpty ||
            widget.model.thumbnail.trim().isNotEmpty;
        final hlsNotReady = widget.model.hlsStatus != 'ready' ||
            widget.model.hlsMasterUrl.trim().isEmpty;
        if (hasVideo && hlsNotReady) {
          final startMs = widget.model.hlsUpdatedAt > 0
              ? widget.model.hlsUpdatedAt.toInt()
              : widget.model.timeStamp.toInt();
          final elapsedMin =
              ((DateTime.now().millisecondsSinceEpoch - startMs) / 60000)
                  .clamp(0, 30);
          progress = 0.9 + (elapsedMin / 30) * 0.09;
        }
      }

      if (progress == null) return const SizedBox.shrink();
      if (progress <= 0) {
        progress = 0.02;
      }
      return RingUploadProgressIndicator(
        isUploading: true,
        progress: progress,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload,
            size: 12,
            color: Colors.black54,
          ),
        ),
      );
    });
  }

  String _pollRemainingLabel({
    required bool expired,
    required int expiresAtMs,
  }) {
    if (expired) return 'Süre Doldu';
    final remainingMs = expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 'Süre Doldu';
    final totalMinutes = (remainingMs / 60000).floor();
    final totalHours = (totalMinutes / 60).floor();
    final days = (totalHours / 24).floor();
    if (days >= 1) return '$days g';
    final hours = totalHours;
    final minutes = totalMinutes % 60;
    return '$hours sa $minutes dk';
  }

  Widget gonderiGizlendi(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            12.ph,
            Text(
              'post_state.hidden_title'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(color: Colors.grey),
            ),
            SizedBox(height: 7),
            Text(
              'post_state.hidden_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: "Montserrat",
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                controller.gizlemeyiGeriAl();
                videoController?.play();
              },
              child: Text(
                'common.undo'.tr,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'post_state.archived_title'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(color: Colors.grey),
            ),
            SizedBox(height: 7),
            Text(
              'post_state.archived_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: "Montserrat",
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                controller.arsivdenCikart();
                videoController?.play();
              },
              child: Text(
                'common.undo'.tr,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'post_state.deleted_title'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(color: Colors.grey),
            ),
            SizedBox(height: 7),
            Text(
              'post_state.deleted_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: "Montserrat",
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSlot(
    Widget child, {
    bool pullTowardSend = false,
  }) {
    return SizedBox(
      width: 58,
      child: Transform.translate(
        offset: Offset(pullTowardSend ? 6 : 3, 0),
        child: Center(child: child),
      ),
    );
  }
}
