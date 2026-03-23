part of 'market_view.dart';

class _MarketGridMedia extends StatefulWidget {
  const _MarketGridMedia({
    required this.item,
    required this.accent,
    required this.radius,
    required this.fallbackBuilder,
  });

  final MarketItemModel item;
  final Color accent;
  final double radius;
  final Widget Function(MarketItemModel item, Color accent) fallbackBuilder;

  @override
  State<_MarketGridMedia> createState() => _MarketGridMediaState();
}

class _MarketGridMediaState extends State<_MarketGridMedia> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.item.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    final allImages = imageUrls.isNotEmpty
        ? imageUrls
        : (widget.item.coverImageUrl.trim().isNotEmpty
            ? <String>[widget.item.coverImageUrl]
            : const <String>[]);

    if (allImages.length <= 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Container(
          color: widget.accent.withValues(alpha: 0.12),
          child: allImages.isNotEmpty
              ? Image.network(
                  allImages.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      widget.fallbackBuilder(widget.item, widget.accent),
                )
              : widget.fallbackBuilder(widget.item, widget.accent),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: allImages.length,
              onPageChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _pageIndex = value;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  color: widget.accent.withValues(alpha: 0.12),
                  child: Image.network(
                    allImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        widget.fallbackBuilder(widget.item, widget.accent),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(allImages.length, (index) {
                final selected = index == _pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: selected ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
