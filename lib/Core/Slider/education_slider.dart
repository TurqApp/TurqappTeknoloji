import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      unawaited(_warmImages(snapshot.items));
    }

    if (snapshot.isFresh) return;

    unawaited(_refreshRemote(sliderId));
  }

  Future<void> _refreshRemote(String sliderId) async {
    try {
      final sliderRef =
          FirebaseFirestore.instance.collection('sliders').doc(sliderId);
      final results = await Future.wait([
        sliderRef.get(const GetOptions(source: Source.serverAndCache)),
        sliderRef
            .collection('items')
            .orderBy('order')
            .get(const GetOptions(source: Source.serverAndCache)),
      ]);

      final metaSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final itemsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

      final hiddenDefaults =
          ((metaSnapshot.data()?['hiddenDefaults'] as List<dynamic>?) ??
                  const <dynamic>[])
              .map((e) => e is num ? e.toInt() : -1)
              .where((e) => e >= 0)
              .toSet();

      final defaults = SliderCatalog.defaultImagesFor(sliderId);
      final sourceImages = <String>[];
      final remoteByOrder = <int, String>{};
      final extras = <String>[];

      for (final doc in itemsSnapshot.docs) {
        final order = (doc.data()['order'] as num?)?.toInt() ?? 0;
        final url = (doc.data()['imageUrl'] ?? '').toString().trim();
        if (url.isEmpty) continue;
        if (order < defaults.length) {
          remoteByOrder[order] = url;
        } else {
          extras.add(url);
        }
      }

      for (var i = 0; i < defaults.length; i++) {
        if (hiddenDefaults.contains(i) && !remoteByOrder.containsKey(i)) {
          continue;
        }
        final remote = remoteByOrder[i];
        if (remote != null && remote.isNotEmpty) {
          sourceImages.add(remote);
          continue;
        }
        final fallback = defaults[i];
        if (fallback.isNotEmpty) {
          sourceImages.add(fallback);
        }
      }
      sourceImages.addAll(extras);

      final resolved = sourceImages.isEmpty ? _defaultSources() : sourceImages;
      _setSources(resolved);
      await _cache.writeResolvedSources(sliderId, resolved);
      unawaited(_warmImages(resolved));
    } catch (_) {}
  }

  Future<void> _warmImages(List<String> sources) async {
    for (final url in sources.where((e) => e.startsWith('http')).take(8)) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
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
