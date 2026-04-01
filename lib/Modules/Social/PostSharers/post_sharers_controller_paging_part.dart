part of 'post_sharers_controller.dart';

extension PostSharersControllerPagingPart on PostSharersController {
  Future<void> loadMoreSharers() async {
    if (_isFetching || !hasMore.value || _resolvedPostId.isEmpty) return;
    if (_usingFallbackSharers) {
      _appendFallbackPage();
      return;
    }
    _isFetching = true;
    isLoadingMore.value = true;

    try {
      final page = await _postRepository.fetchPostSharersPage(
        _resolvedPostId,
        lastDoc: _lastSharerDoc,
        limit: _postSharersPageSize,
      );
      if (page.items.isEmpty) {
        hasMore.value = false;
        return;
      }

      _lastSharerDoc = page.lastDoc;
      hasMore.value = page.hasMore;

      final existingKeys = postSharers
          .map(
            (item) => '${item.userID}_${item.sharedPostID}_${item.timestamp}',
          )
          .toSet();
      final newItems = page.items.where((item) {
        final key = '${item.userID}_${item.sharedPostID}_${item.timestamp}';
        return existingKeys.add(key);
      }).toList(growable: false);

      if (newItems.isEmpty) {
        if (!page.hasMore) {
          hasMore.value = false;
        }
        return;
      }

      postSharers.addAll(newItems);
      final missingUserIds = newItems
          .map((item) => item.userID.trim())
          .where((id) => id.isNotEmpty && !usersData.containsKey(id))
          .toSet()
          .toList(growable: false);
      await loadUsersData(missingUserIds);
    } catch (_) {
    } finally {
      _isFetching = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadUsersData(List<String> userIDs) async {
    if (userIDs.isEmpty) return;
    try {
      final userData = Map<String, Map<String, dynamic>>.from(usersData);
      final rawUsers =
          await _userSummaryResolver.resolveMany(userIDs.toSet().toList());
      for (final userID in userIDs.toSet()) {
        final data = rawUsers[userID];
        if (data == null) {
          userData[userID] = {
            'nickname': 'common.unknown_user'.tr,
            'avatarUrl': '',
            'fullName': 'common.unknown_user'.tr,
            'firstName': '',
            'lastName': '',
          };
          continue;
        }
        final fullName = data.displayName.trim();
        final nickname = data.nickname.trim();

        userData[userID] = {
          'nickname': nickname,
          'avatarUrl': data.avatarUrl,
          'fullName': fullName.isNotEmpty ? fullName : 'common.unknown_user'.tr,
          'firstName': fullName,
          'lastName': '',
        };
      }

      usersData.value = userData;
    } catch (_) {}
  }

  Future<void> refreshSharers() async {
    await loadPostSharers();
  }

  void _appendFallbackPage({bool reset = false}) {
    if (!_usingFallbackSharers) return;
    if (reset) {
      _fallbackOffset = 0;
      postSharers.clear();
      hasMore.value = _fallbackSharers.isNotEmpty;
    }
    if (_fallbackOffset >= _fallbackSharers.length) {
      hasMore.value = false;
      return;
    }

    final nextOffset =
        (_fallbackOffset + _postSharersPageSize) > _fallbackSharers.length
            ? _fallbackSharers.length
            : _fallbackOffset + _postSharersPageSize;
    final pageItems = _fallbackSharers.sublist(_fallbackOffset, nextOffset);
    _fallbackOffset = nextOffset;
    postSharers.addAll(pageItems);
    hasMore.value = _fallbackOffset < _fallbackSharers.length;

    final missingUserIds = pageItems
        .map((item) => item.userID.trim())
        .where((id) => id.isNotEmpty && !usersData.containsKey(id))
        .toSet()
        .toList(growable: false);
    if (missingUserIds.isEmpty) return;
    loadUsersData(missingUserIds);
  }

  void _onScroll() {
    if (!scrollController.hasClients || _isFetching || !hasMore.value) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      loadMoreSharers();
    }
  }
}
