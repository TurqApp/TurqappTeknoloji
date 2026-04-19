part of 'cached_user_avatar.dart';

class _CachedUserAvatarState extends State<CachedUserAvatar> {
  bool get _allowAvatarNetworkFetch => !QALabMode.integrationSmokeRun;
  String _resolvedUrl = '';
  String _resolvedFilePath = '';
  String _primedFilePath = '';
  bool _didBootstrap = false;
  bool _bootstrapInFlight = false;
  bool _bootstrapSettled = false;
  bool _didLogLocalReady = false;
  bool _didLogNetworkFallback = false;
  bool _didLogPainted = false;
  final DateTime _mountedAt = DateTime.now();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  void _logAvatarSync(
    String stage, {
    String source = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final surface = widget.debugSurface.trim();
    if (surface.isEmpty) return;
    final key = widget.debugKey.trim().isNotEmpty
        ? widget.debugKey.trim()
        : ((widget.userId ?? '').trim().isNotEmpty
            ? (widget.userId ?? '').trim()
            : _resolvedUrl);
    final elapsedMs = DateTime.now().difference(_mountedAt).inMilliseconds;
    debugPrint(
      '[AvatarSync][$surface][$key] stage=$stage '
      'elapsedMs=$elapsedMs source=$source '
      'metadata=${<String, dynamic>{
        'hasResolvedUrl': _resolvedUrl.isNotEmpty,
        'hasResolvedFilePath': _resolvedFilePath.isNotEmpty,
        'rememberedHit': _rememberedFilePathFor(_resolvedUrl).isNotEmpty,
        ...metadata,
      }}',
    );
  }

  String _rememberedFilePathFor(String url) =>
      TurqImageCacheManager.rememberedResolvedFilePathForUrl(url);

  String _initialResolvedUrl() {
    final direct = _normalizeUrl(widget.imageUrl);
    if (direct.isNotEmpty) return direct;

    final uid = (widget.userId ?? '').trim();
    if (uid.isEmpty) return '';

    final currentUser = CurrentUserService.instance;
    if (uid == currentUser.effectiveUserId) {
      final currentAvatar = _normalizeUrl(currentUser.avatarUrl);
      if (currentAvatar.isNotEmpty) return currentAvatar;
      final streamAvatar =
          _normalizeUrl((currentUser.currentUser?.avatarUrl ?? '').trim());
      if (streamAvatar.isNotEmpty) return streamAvatar;
    }

    return '';
  }

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
    _resolvedUrl = _initialResolvedUrl();
    _resolvedFilePath = _rememberedFilePathFor(_resolvedUrl);
    _primeResolvedFileFrame(_resolvedFilePath);
    _bootstrapInFlight = true;
    _bootstrapSettled = false;
    _logAvatarSync(
      'mount',
      source: 'init_state',
      metadata: <String, dynamic>{
        'initialUrlPresent': _resolvedUrl.isNotEmpty,
        'initialRememberedFilePathPresent': _resolvedFilePath.isNotEmpty,
      },
    );
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(covariant CachedUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextResolved = _initialResolvedUrl();
    if (oldWidget.userId != widget.userId ||
        oldWidget.imageUrl != widget.imageUrl) {
      final sameUser =
          (oldWidget.userId ?? '').trim() == (widget.userId ?? '').trim();
      final shouldPreserveResolvedUrl =
          sameUser && widget.imageUrl == null && _resolvedUrl.isNotEmpty;
      _resolvedUrl = shouldPreserveResolvedUrl ? _resolvedUrl : nextResolved;
      _resolvedFilePath = shouldPreserveResolvedUrl
          ? _resolvedFilePath
          : _rememberedFilePathFor(_resolvedUrl);
      _primeResolvedFileFrame(_resolvedFilePath);
      _didBootstrap = false;
      _bootstrapInFlight = true;
      _bootstrapSettled = false;
      unawaited(_bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    if (_didBootstrap) return;
    _didBootstrap = true;
    _bootstrapInFlight = true;
    _bootstrapSettled = false;

    try {
      if (_resolvedUrl.isNotEmpty) {
        await _resolveLocalFile(_resolvedUrl, allowNetwork: false);
      }

      final uid = (widget.userId ?? '').trim();
      if (uid.isEmpty) {
        await _resolveLocalFile(
          _resolvedUrl,
          allowNetwork: _allowAvatarNetworkFetch,
        );
        return;
      }

      final currentUser = CurrentUserService.instance;
      if (uid == currentUser.effectiveUserId) {
        final currentAvatar = _normalizeUrl(currentUser.avatarUrl);
        _resolvedUrl = currentAvatar;
        await _resolveLocalFile(
          currentAvatar,
          allowNetwork: _allowAvatarNetworkFetch,
        );
        if (currentUser.currentUser != null) {
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
            await _resolveLocalFile(
              currentRawUrl,
              allowNetwork: _allowAvatarNetworkFetch,
            );
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
        if (cachedRawUrl.isNotEmpty &&
            cachedRawUrl != _resolvedUrl &&
            mounted) {
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
          await _resolveLocalFile(
            fetchedUrl,
            allowNetwork: _allowAvatarNetworkFetch,
          );
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
          await _resolveLocalFile(
            fetchedRawUrl,
            allowNetwork: _allowAvatarNetworkFetch,
          );
        }
      } catch (_) {}
    } finally {
      _bootstrapInFlight = false;
      _bootstrapSettled = true;
      if (mounted) {
        setState(() {});
      }
    }
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
      if (nextPath.isNotEmpty) {
        TurqImageCacheManager.rememberResolvedFile(normalized, nextPath);
      }
      if (nextPath != _resolvedFilePath && mounted) {
        setState(() {
          _resolvedFilePath = nextPath;
        });
      }
      _primeResolvedFileFrame(nextPath);
      if (nextPath.isNotEmpty && !_didLogLocalReady) {
        _didLogLocalReady = true;
        _logAvatarSync(
          'local_file_ready',
          source: allowNetwork ? 'cache_or_network' : 'cache_only',
          metadata: <String, dynamic>{
            'url': normalized,
          },
        );
      }
    } catch (_) {}
  }

  void _primeResolvedFileFrame(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty || normalized == _primedFilePath) {
      return;
    }
    final file = File(normalized);
    if (!file.existsSync()) {
      return;
    }
    _primedFilePath = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        precacheImage(FileImage(file), context).catchError((_) {}),
      );
    });
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
          final currentUserImage = (() {
            final direct = _normalizeUrl(userService.avatarUrl);
            if (direct.isNotEmpty) return direct;
            return _normalizeUrl((snapshot.data?.avatarUrl ?? '').trim());
          })();
          if (currentUserImage.isNotEmpty && currentUserImage != _resolvedUrl) {
            _resolvedUrl = currentUserImage;
            _didBootstrap = false;
            _bootstrapInFlight = true;
            _bootstrapSettled = false;
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
      if (_shouldDeferDefaultAvatar()) {
        return widget.placeholder ?? _buildPendingAvatarPlaceholder();
      }
      return widget.placeholder ??
          DefaultAvatar(
            radius: widget.radius,
            backgroundColor: widget.backgroundColor,
          );
    }
    if (_resolvedFilePath.isEmpty) {
      final rememberedPath = _rememberedFilePathFor(url);
      if (rememberedPath.isNotEmpty) {
        _resolvedFilePath = rememberedPath;
        _primeResolvedFileFrame(rememberedPath);
      }
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
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if ((wasSynchronouslyLoaded || frame != null) &&
                    !_didLogPainted) {
                  _didLogPainted = true;
                  _logAvatarSync(
                    'painted',
                    source: wasSynchronouslyLoaded
                        ? 'image_file_sync'
                        : 'image_file_frame',
                  );
                }
                return child;
              },
            ),
          ),
        );
      }
    }
    return _buildNetworkAvatar(url);
  }

  Widget _buildNetworkAvatar(String imageUrl) {
    final fallback = widget.placeholder ??
        widget.errorWidget ??
        DefaultAvatar(
          radius: widget.radius,
          backgroundColor: widget.backgroundColor,
        );
    if (!_allowAvatarNetworkFetch) {
      return fallback;
    }
    if (!_didLogNetworkFallback) {
      _didLogNetworkFallback = true;
      _logAvatarSync(
        'network_fallback',
        source: 'build_network_avatar',
        metadata: <String, dynamic>{
          'url': imageUrl,
        },
      );
    }
    final size = widget.radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CacheFirstNetworkImage(
          imageUrl: imageUrl,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          downloadBeforeRender: true,
          fallback: fallback,
          memCacheWidth: size.round(),
          memCacheHeight: size.round(),
        ),
      ),
    );
  }

  String _normalizeUrl(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (isDefaultAvatarUrl(trimmed)) return '';
    return CdnUrlBuilder.toCdnUrl(trimmed);
  }

  bool _shouldDeferDefaultAvatar() {
    if (_bootstrapSettled || !_bootstrapInFlight) return false;
    if (_resolvedFilePath.isNotEmpty || _resolvedUrl.isNotEmpty) return true;
    if ((widget.userId ?? '').trim().isNotEmpty) return true;
    return _normalizeUrl(widget.imageUrl).isNotEmpty;
  }

  Widget _buildPendingAvatarPlaceholder() {
    final size = widget.radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: widget.backgroundColor ?? const Color(0xFFE7EDF2),
        ),
      ),
    );
  }
}
