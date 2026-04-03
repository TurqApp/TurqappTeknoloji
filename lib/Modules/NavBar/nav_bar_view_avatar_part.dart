part of 'nav_bar_view.dart';

class _AvatarWithRing extends StatefulWidget {
  final String userId;
  final String imageUrl;
  final double size;
  final bool isSelected;
  final bool uploading;
  final double angle;

  const _AvatarWithRing({
    required this.userId,
    required this.imageUrl,
    required this.size,
    required this.isSelected,
    required this.uploading,
    required this.angle,
  });

  @override
  State<_AvatarWithRing> createState() => _AvatarWithRingState();
}

class _AvatarWithRingState extends State<_AvatarWithRing> {
  double _scale = 1.0;
  late String _stableUserId;
  late String _stableImageUrl;

  @override
  void initState() {
    super.initState();
    _stableUserId = widget.userId.trim();
    _stableImageUrl = widget.imageUrl.trim();
  }

  @override
  void didUpdateWidget(covariant _AvatarWithRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextUserId = widget.userId.trim();
    final nextImageUrl = widget.imageUrl.trim();
    if (nextUserId.isNotEmpty) {
      _stableUserId = nextUserId;
    }
    if (nextImageUrl.isNotEmpty) {
      _stableImageUrl = nextImageUrl;
    }
  }

  void _down(PointerDownEvent e) {
    setState(() => _scale = 0.75);
  }

  void _up(PointerUpEvent e) {
    setState(() => _scale = 1.0);
  }

  void _cancel(PointerCancelEvent e) {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CachedUserAvatar(
      userId: _stableUserId.isNotEmpty ? _stableUserId : widget.userId,
      imageUrl: _stableImageUrl.isNotEmpty ? _stableImageUrl : widget.imageUrl,
      radius: widget.size / 2,
      backgroundColor: Colors.transparent,
      placeholder: DefaultAvatar(
        radius: widget.size / 2,
        backgroundColor: Colors.transparent,
      ),
      errorWidget: DefaultAvatar(
        radius: widget.size / 2,
        backgroundColor: Colors.transparent,
      ),
    );

    final ringSize = widget.size + 8;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: CustomPaint(
            painter: _RingPainter(
              baseColor: Colors.grey.withValues(alpha: 0.35),
              uploading: widget.uploading,
              angle: widget.angle,
            ),
            child: Center(child: avatar),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color baseColor;
  final bool uploading;
  final double angle;

  _RingPainter({
    required this.baseColor,
    required this.uploading,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 1.5;

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, basePaint);

    if (uploading) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..shader = SweepGradient(
          colors: [AppColors.primaryColor, AppColors.secondColor],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final arcLength = math.pi * 0.9;
      final start = angle;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, arcLength, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.uploading != uploading ||
        oldDelegate.angle != angle;
  }
}
