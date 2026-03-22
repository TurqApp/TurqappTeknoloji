part of 'edit_post.dart';

extension _EditPostMediaPart on _EditPostState {
  Widget _buildContentFromUrls(List<String> urls) {
    switch (urls.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 1,
          child: _buildUrlTile(urls, 0, BorderRadius.circular(12)),
        );
      case 2:
        return _buildTwoUrlGrid(urls);
      case 3:
        return _buildThreeUrlGrid(urls);
      default:
        return _buildFourUrlGrid(urls);
    }
  }

  Widget _buildTwoUrlGrid(List<String> urls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                child: _buildUrlTile(
                  urls,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: _buildUrlTile(
                  urls,
                  1,
                  const BorderRadius.only(
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

  Widget _buildThreeUrlGrid(List<String> urls) {
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
                child: _buildUrlTile(
                  urls,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildUrlTile(
                        urls,
                        1,
                        const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                      child: _buildUrlTile(
                        urls,
                        2,
                        const BorderRadius.only(
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

  Widget _buildFourUrlGrid(List<String> urls) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: min(urls.length, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildUrlTile(urls, index, radius);
      },
    );
  }

  Widget _buildUrlTile(List<String> urls, int index, BorderRadius radius) {
    final url = urls[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => const CupertinoActivityIndicator(),
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: () => controller.removeImageUrl(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentFromFiles(List<File> files) {
    switch (files.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 1,
          child: _buildFileTile(files, 0, BorderRadius.circular(12)),
        );
      case 2:
        return _buildTwoFileGrid(files);
      case 3:
        return _buildThreeFileGrid(files);
      default:
        return _buildFourFileGrid(files);
    }
  }

  Widget _buildTwoFileGrid(List<File> files) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                child: _buildFileTile(
                  files,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: _buildFileTile(
                  files,
                  1,
                  const BorderRadius.only(
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

  Widget _buildThreeFileGrid(List<File> files) {
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
                child: _buildFileTile(
                  files,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildFileTile(
                        files,
                        1,
                        const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                      child: _buildFileTile(
                        files,
                        2,
                        const BorderRadius.only(
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

  Widget _buildFourFileGrid(List<File> files) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: min(files.length, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildFileTile(files, index, radius);
      },
    );
  }

  Widget _buildFileTile(List<File> files, int index, BorderRadius radius) {
    final file = files[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: () => controller.removeSelectedImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
