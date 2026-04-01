import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/Ads/ads_analytics_service.dart';
import 'package:turqappv2/Core/Services/slider_cache_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';
import 'package:visibility_detector/visibility_detector.dart';

class EducationSlider extends StatefulWidget {
  final List<String> imageList;
  final String? sliderId;

  const EducationSlider({
    super.key,
    required this.imageList,
    this.sliderId,
  });

  @override
  State<EducationSlider> createState() => _EducationSliderState();
}

class _EducationSliderState extends State<EducationSlider> {
  final SliderCacheService _cache = SliderCacheService();
  final AdsAnalyticsService _analytics = const AdsAnalyticsService();
  List<SliderResolvedItem> _items = const <SliderResolvedItem>[];
  bool _bootstrapped = false;
  int _currentIndex = 0;
  bool _isVisible = false;
  late final Key _visibilityKey;

  @override
  void initState() {
    super.initState();
    _visibilityKey = ValueKey<String>(
        'education-slider-${widget.sliderId ?? identityHashCode(this)}');
    _items = _defaultItems();
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(covariant EducationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sliderId != widget.sliderId ||
        oldWidget.imageList != widget.imageList) {
      _items = _defaultItems();
      _bootstrapped = false;
      _currentIndex = 0;
      unawaited(_bootstrap());
    }
  }

  List<String> _defaultSources() {
    final sliderId = widget.sliderId?.trim() ?? '';
    if (sliderId.isNotEmpty) {
      final defaults = SliderCatalog.defaultImagesFor(sliderId);
      if (defaults.isNotEmpty) return defaults;
    }
    return widget.imageList;
  }

  List<SliderResolvedItem> _defaultItems() {
    return _defaultSources()
        .asMap()
        .entries
        .map(
          (entry) => SliderResolvedItem(
            itemId: 'default_${entry.key}',
            source: entry.value,
            order: entry.key,
            startDateMs: 0,
            endDateMs: 0,
            viewCount: 0,
            uniqueViewCount: 0,
            isRemote: false,
            isDefault: true,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final sliderId = widget.sliderId?.trim() ?? '';
    if (sliderId.isEmpty) {
      _setItems(_defaultItems());
      return;
    }

    final snapshot = await _cache.readSnapshot(sliderId);
    if (snapshot.hasItems) {
      _setItems(snapshot.resolvedItems);
      unawaited(_cache.warmImages(snapshot.items));
    }
    unawaited(_refreshRemote(sliderId));
  }

  Future<void> _refreshRemote(String sliderId) async {
    try {
      final remote = await _cache.refreshAndCacheItems(sliderId);
      final resolved = remote.isEmpty ? _defaultItems() : remote;
      _setItems(resolved);
    } catch (_) {}
  }

  void _setItems(List<SliderResolvedItem> next) {
    if (!mounted) return;
    if (_items.length == next.length) {
      var changed = false;
      for (var i = 0; i < next.length; i++) {
        if (_items[i].itemId != next[i].itemId ||
            _items[i].source != next[i].source) {
          changed = true;
          break;
        }
      }
      if (!changed) return;
    }
    setState(() {
      _items = next;
      if (_currentIndex >= _items.length) {
        _currentIndex = 0;
      }
    });
    unawaited(_reportCurrentSlideIfNeeded());
  }

  Future<void> _reportCurrentSlideIfNeeded() async {
    final sliderId = widget.sliderId?.trim() ?? '';
    if (!_isVisible || sliderId.isEmpty || _items.isEmpty) {
      return;
    }
    final item = _items[_currentIndex.clamp(0, _items.length - 1)];
    if (!item.isRemote || item.itemId.trim().isEmpty) {
      return;
    }
    await _analytics.logManagedSliderView(
      sliderId: sliderId,
      itemId: item.itemId,
      surfaceId: sliderId,
      sourceType: 'top_slider',
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (info) {
        final nextVisible = info.visibleFraction > 0.01;
        if (_isVisible == nextVisible) {
          return;
        }
        _isVisible = nextVisible;
        if (_isVisible) {
          unawaited(_reportCurrentSlideIfNeeded());
        }
      },
      child: _buildCarousel(context, _items),
    );
  }

  Widget _buildCarousel(BuildContext context, List<SliderResolvedItem> items) {
    return CarouselSlider(
      items: items.map((item) {
        final imgPath = item.source;
        final isRemote = imgPath.startsWith('http');
        return Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isRemote
                    ? CachedNetworkImage(
                        imageUrl: imgPath,
                        cacheManager: TurqImageCacheManager.instance,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, _) => _buildFallbackCard(),
                        errorWidget: (context, _, __) => _buildFallbackCard(),
                      )
                    : Image.asset(
                        imgPath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, _, __) => _buildFallbackCard(),
                      ),
              ),
            );
          },
        );
      }).toList(),
      options: CarouselOptions(
        autoPlay: true,
        height: MediaQuery.of(context).size.width / 2.7,
        enlargeCenterPage: false,
        autoPlayInterval: const Duration(seconds: 2),
        viewportFraction: 0.9,
        onPageChanged: (index, _) {
          _currentIndex = index;
          unawaited(_reportCurrentSlideIfNeeded());
        },
      ),
    );
  }

  Widget _buildFallbackCard() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}
