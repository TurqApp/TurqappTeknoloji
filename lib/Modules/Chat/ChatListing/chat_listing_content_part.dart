part of 'chat_listing.dart';

class _SwipeActionTile extends StatefulWidget {
  final String tileId;
  final ValueNotifier<String?> openedId;
  final bool isArchiveTab;
  final Widget child;
  final Future<void> Function() onDelete;
  final Future<void> Function() onArchive;

  const _SwipeActionTile({
    super.key,
    required this.tileId,
    required this.openedId,
    this.isArchiveTab = false,
    required this.child,
    required this.onDelete,
    required this.onArchive,
  });

  @override
  State<_SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<_SwipeActionTile> {
  double _offsetX = 0;
  bool _busy = false;
  Timer? _autoCloseTimer;

  double _maxReveal(BuildContext context) =>
      MediaQuery.of(context).size.width / 5;

  Future<void> _handleArchive() async {
    if (_busy) return;
    _autoCloseTimer?.cancel();
    debugPrint("[SwipeArchive] tapped tile=${widget.tileId}");
    setState(() => _busy = true);
    await widget.onArchive();
    if (mounted) {
      setState(() {
        _busy = false;
        _offsetX = 0;
      });
      widget.openedId.value = null;
    }
  }

  Future<void> _handleDelete() async {
    if (_busy) return;
    _autoCloseTimer?.cancel();
    setState(() => _busy = true);
    await widget.onDelete();
    if (mounted) {
      setState(() {
        _busy = false;
        _offsetX = 0;
      });
      widget.openedId.value = null;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.openedId.addListener(_onOpenChanged);
  }

  @override
  void didUpdateWidget(covariant _SwipeActionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openedId != widget.openedId) {
      oldWidget.openedId.removeListener(_onOpenChanged);
      widget.openedId.addListener(_onOpenChanged);
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    widget.openedId.removeListener(_onOpenChanged);
    super.dispose();
  }

  void _onOpenChanged() {
    final currentOpen = widget.openedId.value;
    if (currentOpen != null && currentOpen != widget.tileId && _offsetX != 0) {
      if (mounted) setState(() => _offsetX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reveal = _maxReveal(context);
    final isArchiveOpen = _offsetX > 0;
    final isDeleteOpen = _offsetX < 0;

    return ClipRect(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              _autoCloseTimer?.cancel();
              if (widget.openedId.value != null &&
                  widget.openedId.value != widget.tileId) {
                widget.openedId.value = widget.tileId;
              }
              final next = (_offsetX + (details.primaryDelta ?? 0))
                  .clamp(-reveal, reveal);
              setState(() => _offsetX = next);
            },
            onHorizontalDragEnd: (_) {
              final threshold = reveal * 0.35;
              if (_offsetX.abs() < threshold) {
                setState(() {
                  _offsetX = 0;
                });
                widget.openedId.value = null;
                _autoCloseTimer?.cancel();
                return;
              }
              setState(() => _offsetX = _offsetX > 0 ? reveal : -reveal);
              widget.openedId.value = widget.tileId;
              _autoCloseTimer?.cancel();
              _autoCloseTimer = Timer(const Duration(seconds: 2), () {
                if (!mounted || _busy) return;
                setState(() => _offsetX = 0);
                widget.openedId.value = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_offsetX, 0, 0),
              child: Container(color: Colors.white, child: widget.child),
            ),
          ),
          if (isArchiveOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: reveal,
              child: Material(
                color: widget.isArchiveTab
                    ? const Color(0xFF2D8CFF)
                    : Colors.black,
                child: InkWell(
                  onTap: _handleArchive,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.archivebox,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isArchiveTab
                              ? 'common.unarchive'.tr
                              : 'common.archive'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: "MontserratSemiBold",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (isDeleteOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: reveal,
              child: Material(
                color: const Color(0xFFE53935),
                child: InkWell(
                  onTap: _handleDelete,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'common.delete'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: "MontserratSemiBold",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final String? integrationKey;
  final bool active;
  final VoidCallback? onTap;

  const _TopTab({
    required this.label,
    this.integrationKey,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        key: integrationKey == null ? null : ValueKey(integrationKey!),
        onTap: onTap,
        child: Container(
          height: 44,
          color: Colors.white,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily:
                        active ? "MontserratSemiBold" : "MontserratMedium",
                  ),
                ),
              ),
              if (active)
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.chat_bubble_2,
              size: 56,
              color: Color(0xFFB8BEC5),
            ),
            const SizedBox(height: 14),
            Text(
              'chat.empty_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontFamily: "MontserratSemiBold",
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'chat.empty_body'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7A8087),
                fontSize: 14,
                fontFamily: "MontserratMedium",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
