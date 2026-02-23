import 'package:flutter/material.dart';

/// Bouncy tap wrapper used across agenda action buttons.
class AnimatedActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final String semanticsLabel;
  final EdgeInsetsGeometry padding;
  final bool showTapArea;

  const AnimatedActionButton({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    required this.enabled,
    required this.semanticsLabel,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
    this.showTapArea = false,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  static const double _pressScale = 0.9;
  static const double _releaseScale = 1.0;

  double _holdScale = _releaseScale;
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.24)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.24, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
    ]).animate(_tapController);
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _setHoldScale(double value) {
    if (_holdScale == value) return;
    setState(() => _holdScale = value);
  }

  void _runTapAnimation() {
    _tapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown: widget.enabled ? (_) => _setHoldScale(_pressScale) : null,
        onTapCancel: widget.enabled ? () => _setHoldScale(_releaseScale) : null,
        onTapUp: widget.enabled ? (_) => _setHoldScale(_releaseScale) : null,
        onTap: widget.enabled
            ? () {
                _runTapAnimation();
                widget.onTap?.call();
              }
            : null,
        onLongPress: widget.enabled
            ? () {
                _setHoldScale(_releaseScale);
                widget.onLongPress?.call();
              }
            : null,
        child: AnimatedScale(
          scale: _holdScale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: ScaleTransition(
            scale: _tapScale,
            child: Container(
              decoration: widget.showTapArea
                  ? BoxDecoration(
                      border: Border.all(color: Colors.redAccent, width: 1),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + counter layout with subtle count animation.
class ActionButtonContent extends StatelessWidget {
  final Widget leading;
  final String? label;
  final TextStyle? labelStyle;
  final double gap;

  const ActionButtonContent({
    super.key,
    required this.leading,
    this.label,
    this.labelStyle,
    this.gap = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leading,
        if (label != null) ...[
          SizedBox(width: gap),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Text(
              label!,
              key: ValueKey<String>(label!),
              style: labelStyle ??
                  const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'MontserratMedium',
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
