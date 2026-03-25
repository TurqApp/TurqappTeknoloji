part of 'cached_user_avatar.dart';

class _CachedUserAvatarState extends State<CachedUserAvatar> {
  String _resolvedUrl = '';
  String _resolvedFilePath = '';
  bool _didBootstrap = false;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  String _pickAvatarUrl(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return '';
    Map<String, dynamic>? nestedProfile;
    final rawProfile = raw['profile'];
    if (rawProfile is Map) {
      nestedProfile = Map<String, dynamic>.from(rawProfile);
    }
    final rawPublicProfile = raw['publicProfile'];
    if (rawPublicProfile is Map) {
      nestedProfile ??= Map<String, dynamic>.from(rawPublicProfile);
    }
    return resolveAvatarUrl(raw, profile: nestedProfile);
  }

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _normalizeUrl(widget.imageUrl);
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(covariant CachedUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextResolved = _normalizeUrl(widget.imageUrl);
    if (oldWidget.userId != widget.userId ||
        oldWidget.imageUrl != widget.imageUrl) {
      final sameUser =
          (oldWidget.userId ?? '').trim() == (widget.userId ?? '').trim();
      final shouldPreserveResolvedUrl =
          sameUser && nextResolved.isEmpty && _resolvedUrl.isNotEmpty;
      _resolvedUrl = shouldPreserveResolvedUrl ? _resolvedUrl : nextResolved;
      _didBootstrap = false;
      unawaited(_bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    if (_didBootstrap) return;
    _didBootstrap = true;

    final uid = (widget.userId ?? '').trim();
    if (uid.isEmpty) {
      await _resolveLocalFile(_resolvedUrl, allowNetwork: true);
      return;
    }

    final currentUser = CurrentUserService.instance;
    if (uid == currentUser.effectiveUserId) {
      final currentAvatar = _normalizeUrl(currentUser.avatarUrl);
      if (currentAvatar.isNotEmpty) {
        _resolvedUrl = currentAvatar;
        await _resolveLocalFile(currentAvatar, allowNetwork: true);
        return;
      }

      try {
        final currentRaw = await UserRepository.ensure().getUserRaw(
          uid,
          preferCache: true,
          cacheOnly: false,
          forceServer: true,
        );
        final currentRawUrl = _pickAvatarUrl(currentRaw);
        if (currentRawUrl.isNotEmpty) {
          _resolvedUrl = currentRawUrl;
          await _resolveLocalFile(currentRawUrl, allowNetwork: true);
          return;
        }
      } catch (_) {}
    }

    final users = UserRepository.ensure();

    try {
      final cached = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final cachedUrl = _normalizeUrl(cached?.avatarUrl);
      if (cachedUrl.isNotEmpty && cachedUrl != _resolvedUrl && mounted) {
        setState(() {
          _resolvedUrl = cachedUrl;
        });
      }
      if (cachedUrl.isNotEmpty) {
        await _resolveLocalFile(cachedUrl, allowNetwork: false);
      }
    } catch (_) {}

    try {
      final cachedRaw = await users.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final cachedRawUrl = _pickAvatarUrl(cachedRaw);
      if (cachedRawUrl.isNotEmpty && cachedRawUrl != _resolvedUrl && mounted) {
        setState(() {
          _resolvedUrl = cachedRawUrl;
        });
      }
      if (cachedRawUrl.isNotEmpty) {
        await _resolveLocalFile(cachedRawUrl, allowNetwork: false);
      }
    } catch (_) {}

    if (_resolvedUrl.isNotEmpty) return;

    try {
      final fetched = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
        cacheOnly: false,
      );
      final fetchedUrl = _normalizeUrl(fetched?.avatarUrl);
      if (fetchedUrl.isNotEmpty && fetchedUrl != _resolvedUrl && mounted) {
        setState(() {
          _resolvedUrl = fetchedUrl;
        });
      }
      if (fetchedUrl.isNotEmpty) {
        await _resolveLocalFile(fetchedUrl, allowNetwork: true);
      }
    } catch (_) {}

    if (_resolvedUrl.isNotEmpty) return;

    try {
      final fetchedRaw = await users.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: false,
        forceServer: true,
      );
      final fetchedRawUrl = _pickAvatarUrl(fetchedRaw);
      if (fetchedRawUrl.isNotEmpty &&
          fetchedRawUrl != _resolvedUrl &&
          mounted) {
        setState(() {
          _resolvedUrl = fetchedRawUrl;
        });
      }
      if (fetchedRawUrl.isNotEmpty) {
        await _resolveLocalFile(fetchedRawUrl, allowNetwork: true);
      }
    } catch (_) {}
  }

  Future<void> _resolveLocalFile(
    String url, {
    required bool allowNetwork,
  }) async {
    final normalized = _normalizeUrl(url);
    if (normalized.isEmpty) {
      if (_resolvedFilePath.isNotEmpty && mounted) {
        setState(() {
          _resolvedFilePath = '';
        });
      }
      return;
    }
    try {
      final cached = await TurqImageCacheManager.instance.getFileFromCache(
        normalized,
      );
      File? file = cached?.file;
      if ((file == null || !file.existsSync()) && allowNetwork) {
        file = await TurqImageCacheManager.instance.getSingleFile(normalized);
      }
      final nextPath = (file != null && file.existsSync()) ? file.path : '';
      if (nextPath != _resolvedFilePath && mounted) {
        setState(() {
          _resolvedFilePath = nextPath;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final userService = CurrentUserService.instance;
    final uid = (widget.userId ?? '').trim();

    if (uid.isNotEmpty && uid == userService.effectiveUserId) {
      return StreamBuilder(
        stream: userService.userStream,
        initialData: userService.currentUser,
        builder: (context, snapshot) {
          final currentUserImage =
              _normalizeUrl((snapshot.data?.avatarUrl ?? '').trim());
          if (currentUserImage.isNotEmpty && currentUserImage != _resolvedUrl) {
            _resolvedUrl = currentUserImage;
            _didBootstrap = false;
            unawaited(_bootstrap());
          }
          return _buildAvatar(
            currentUserImage.isNotEmpty ? currentUserImage : _resolvedUrl,
          );
        },
      );
    }

    return _buildAvatar(_resolvedUrl);
  }

  Widget _buildAvatar(String url) {
    if (url.isEmpty) {
      return widget.placeholder ??
          DefaultAvatar(
            radius: widget.radius,
            backgroundColor: widget.backgroundColor,
          );
    }
    if (_resolvedFilePath.isNotEmpty) {
      final file = File(_resolvedFilePath);
      if (file.existsSync()) {
        final size = widget.radius * 2;
        return ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        );
      }
    }
    return _buildNetworkAvatar(url);
  }

  Widget _buildNetworkAvatar(String imageUrl) {
    final size = widget.radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              widget.placeholder ??
              Container(color: widget.backgroundColor ?? Colors.grey[300]),
          errorWidget: (_, __, ___) =>
              widget.errorWidget ??
              DefaultAvatar(
                radius: widget.radius,
                backgroundColor: widget.backgroundColor,
              ),
        ),
      ),
    );
  }

  String _normalizeUrl(String? raw) {
    final trimmed = (raw ?? '').trim();
    return isDefaultAvatarUrl(trimmed) ? '' : trimmed;
  }
}
