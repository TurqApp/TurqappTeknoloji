part of 'creator_content.dart';

extension CreatorContentMediaImagePart on CreatorContent {
  List<Uint8List?> _currentImagePreviewBytes() {
    final cropped =
        controller.croppedImages.whereType<Uint8List>().toList(growable: false);
    if (cropped.isNotEmpty) {
      return cropped.cast<Uint8List?>();
    }

    if (controller.selectedImages.isEmpty) {
      return const <Uint8List?>[];
    }

    final selected = <Uint8List?>[];
    for (final file in controller.selectedImages) {
      try {
        selected.add(file.readAsBytesSync());
      } catch (_) {
        selected.add(null);
      }
    }
    return selected;
  }

  Widget buildImageGridFromMemory(List<Uint8List?> images) {
    images = images.where((e) => e != null).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: outerRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildMediaLookPreview(
            controller.videoLookPreset.value,
            _buildImageContentFromMemory(images),
            applyMatrix: false,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              controller.selectedImages.clear();
              controller.croppedImages.clear();
              controller.reusedImageUrls.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContentFromMemory(List<Uint8List?> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: _singleImagePreviewAspect,
          child:
              _buildMemoryImage(images[0]!, radius: BorderRadius.circular(12)),
        );
      case 2:
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildMemoryImage(
                    images[0]!,
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildMemoryImage(
                    images[1]!,
                    radius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 3:
        return AspectRatio(
          aspectRatio: 1,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: _buildMemoryImage(
                    images[0]!,
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: _buildMemoryImage(
                          images[1]!,
                          radius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: _buildMemoryImage(
                          images[2]!,
                          radius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 4:
      default:
        return buildFourImageGridFromMemory(images);
    }
  }

  Widget buildImageGridFromUrls(List<String> imageUrls) {
    final urls =
        imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: outerRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildMediaLookPreview(
            controller.videoLookPreset.value,
            _buildImageContentFromUrls(urls),
            applyMatrix: false,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              controller.reusedImageUrls.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContentFromUrls(List<String> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: _singleImagePreviewAspect,
          child: _buildNetworkImage(
            images[0],
            radius: BorderRadius.circular(12),
          ),
        );
      case 2:
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildNetworkImage(
                    images[0],
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildNetworkImage(
                    images[1],
                    radius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 3:
        return AspectRatio(
          aspectRatio: 1,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: _buildNetworkImage(
                    images[0],
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: _buildNetworkImage(
                          images[1],
                          radius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: _buildNetworkImage(
                          images[2],
                          radius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 4:
      default:
        return Column(
          children: [
            Row(
              children: List.generate(2, (index) {
                final img = images[index];
                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius: _getRadius(index),
                        child:
                            _buildNetworkImage(img, radius: BorderRadius.zero),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Row(
              children: List.generate(2, (index) {
                final img = images[index + 2];
                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius: _getRadius(index + 2),
                        child:
                            _buildNetworkImage(img, radius: BorderRadius.zero),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
    }
  }

  Widget buildFourImageGridFromMemory(List<Uint8List?> images) {
    return Column(
      children: [
        Row(
          children: List.generate(2, (index) {
            final img = images[index];
            return Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: _getRadius(index),
                    child: Image.memory(img!, fit: BoxFit.cover),
                  ),
                ),
              ),
            );
          }),
        ),
        Row(
          children: List.generate(2, (index) {
            final img = images[index + 2];
            return Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: _getRadius(index + 2),
                    child: Image.memory(img!, fit: BoxFit.cover),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMemoryImage(Uint8List data, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Image.memory(
          data,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
      ),
    );
  }

  BorderRadius _getRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
      default:
        return BorderRadius.zero;
    }
  }
}
