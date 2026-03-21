import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_circle.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';

class StoryRow extends StatefulWidget {
  const StoryRow({super.key});
  static const double _storyRowHeight = 90;
  static const double _storyRowLeadingPadding = 10;
  static const double _storyRowItemSpacing = 10;

  @override
  State<StoryRow> createState() => _StoryRowState();
}

class _StoryRowState extends State<StoryRow> {
  late final StoryRowController controller;
  bool _ownsController = false;

  StoryInteractionOptimizer get _storyOptimizer => StoryInteractionOptimizer.to;

  @override
  void initState() {
    super.initState();
    final existingController = StoryRowController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = StoryRowController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(StoryRowController.maybeFind(), controller)) {
      Get.delete<StoryRowController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // OPTİMİZE EDİLMİŞ REACTİVE: Local cache'den dinle
      _storyOptimizer.localStoryCache.length;
      _storyOptimizer.localTimeCache.length;

      final hasData = controller.users.isNotEmpty;

      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: hasData
            ? SizedBox(
                height: StoryRow._storyRowHeight,
                width: double.infinity,
                child: ListView.builder(
                  key: const ValueKey('story_real'),
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.users.length,
                  itemBuilder: (context, index) {
                    final user = controller.users[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? StoryRow._storyRowLeadingPadding : 0,
                        right: StoryRow._storyRowItemSpacing,
                      ),
                      child: StoryCircle(
                        key: ValueKey('circle_${user.userID}'),
                        model: user,
                        users: controller.users,
                        isFirst: index == 0,
                      ),
                    );
                  },
                ),
              )
            : SizedBox(
                height: StoryRow._storyRowHeight,
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      controller.addMyUserImmediately();
                    });
                    return const StoryRowPlaceholder();
                  },
                ),
              ),
      );
    });
  }
}

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
        final t = _ctrl.value; // 0..1
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
  final double progress; // 0..1
  final int index;
  const _ShimmerCircle({required this.progress, required this.index});

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.withValues(alpha: 0.18);
    final highlight = Colors.grey.withValues(alpha: 0.32);
    final width = 70.0;

    // Per-item faz offset ile lineer shimmer (Instagram benzeri)
    final t = (progress + index * 0.12) % 1.0; // 0..1
    // -1.2 .. 1.2 arasında akış, band genişliği ~0.4
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
