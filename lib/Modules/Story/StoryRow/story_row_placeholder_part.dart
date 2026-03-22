part of 'story_row.dart';

class StoryRowPlaceholder extends StatefulWidget {
  const StoryRowPlaceholder({super.key});

  @override
  State<StoryRowPlaceholder> createState() => _StoryRowPlaceholderState();
}

class _StoryRowPlaceholderState extends State<StoryRowPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = List.generate(6, (i) => i);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? StoryRow._storyRowLeadingPadding : 0,
                right: StoryRow._storyRowItemSpacing,
              ),
              child: _ShimmerCircle(progress: t, index: index),
            );
          },
        );
      },
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  final double progress;
  final int index;

  const _ShimmerCircle({
    required this.progress,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.withValues(alpha: 0.18);
    final highlight = Colors.grey.withValues(alpha: 0.32);
    const width = 70.0;

    final t = (progress + index * 0.12) % 1.0;
    final alignment = Alignment(-1.2 + 2.4 * t, 0);

    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.grey.withValues(alpha: 0.28), width: 2),
      ),
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: alignment - const Alignment(0.4, 0),
            end: alignment + const Alignment(0.4, 0),
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcATop,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: base,
          ),
        ),
      ),
    );
  }
}
