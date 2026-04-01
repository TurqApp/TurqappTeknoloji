part of 'url_post_maker.dart';

extension UrlPostMakerMediaPart on _UrlPostMakerState {
  Widget videobody() {
    return Obx(() {
      final ctrl = controller.videoPlayerController.value;
      if (ctrl != null && ctrl.value.isInitialized) {
        final videoWidth = ctrl.value.size.width;
        final videoHeight = ctrl.value.size.height;
        return Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoWidth,
                      height: videoHeight,
                      child: ctrl.buildPlayer(),
                    ),
                  ),
                  if (widget.sharedAsPost &&
                      (widget.originalUserID ?? '').isNotEmpty)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: SharedPostLabel(
                        originalUserID: widget.originalUserID!,
                        textColor: Colors.white,
                        fontSize: AppTypography.postAttribution.fontSize!,
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Obx(
                      () => GestureDetector(
                        onTap: () {
                          if (controller.isPlaying.value) {
                            ctrl.pause();
                          } else {
                            ctrl.play();
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            controller.isPlaying.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Container();
    });
  }

  Widget buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        GestureDetector(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: outerRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageContent(images),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(List<String> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: _buildImage(images[0], radius: BorderRadius.circular(12)),
        );
      case 2:
        return _buildTwoImageGrid(images);
      case 3:
        return _buildThreeImageGrid(images);
      case 4:
      default:
        return buildFourImageGrid(images);
    }
  }

  Widget buildFourImageGrid(List<String> images) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildImage(images[index], radius: radius);
      },
    );
  }

  Widget _buildThreeImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 1),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildImage(
                        images[1],
                        radius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 1),
                    Expanded(
                      child: _buildImage(
                        images[2],
                        radius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTwoImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 1),
              Expanded(
                child: _buildImage(
                  images[1],
                  radius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String url, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const CupertinoActivityIndicator(),
        ),
      ),
    );
  }

  BorderRadius _getGridRadius(int index) {
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
