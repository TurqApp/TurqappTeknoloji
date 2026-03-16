import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/slider_cache_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';

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
  List<String> _sources = const <String>[];
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _sources = _defaultSources();
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(covariant EducationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sliderId != widget.sliderId ||
        oldWidget.imageList != widget.imageList) {
      _sources = _defaultSources();
      _bootstrapped = false;
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

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final sliderId = widget.sliderId?.trim() ?? '';
    if (sliderId.isEmpty) {
      _setSources(_defaultSources());
      return;
    }

    final snapshot = await _cache.readSnapshot(sliderId);
    if (snapshot.hasItems) {
      _setSources(snapshot.items);
      unawaited(_cache.warmImages(snapshot.items));
    }
    unawaited(_refreshRemote(sliderId));
  }

  Future<void> _refreshRemote(String sliderId) async {
    try {
      final remote = await _cache.refreshAndCacheSources(sliderId);
      final resolved = remote.isEmpty ? _defaultSources() : remote;
      _setSources(resolved);
    } catch (_) {}
  }

  void _setSources(List<String> next) {
    if (!mounted) return;
    if (_sources.length == next.length) {
      var changed = false;
      for (var i = 0; i < next.length; i++) {
        if (_sources[i] != next[i]) {
          changed = true;
          break;
        }
      }
      if (!changed) return;
    }
    setState(() {
      _sources = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCarousel(context, _sources);
  }

  Widget _buildCarousel(BuildContext context, List<String> sources) {
    return CarouselSlider(
      items: sources.map((imgPath) {
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
        autoPlayInterval: const Duration(seconds: 10),
        viewportFraction: 0.9,
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
