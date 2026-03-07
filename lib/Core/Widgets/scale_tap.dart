import 'package:flutter/material.dart';

/// A lightweight press animation wrapper that scales its child slightly
/// on tap down and restores on tap up/cancel. Keeps ripple behavior
/// when a Material/Ink widget exists inside.
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  final Duration duration;
  final bool enabled;

  const ScaleTap({
    super.key,
    required this.child,
    this.onPressed,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 100),
    this.enabled = true,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!widget.enabled) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final double target = _pressed && widget.enabled ? widget.scale : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: target,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
