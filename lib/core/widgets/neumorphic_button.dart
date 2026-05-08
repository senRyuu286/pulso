import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

/// Neumorphic press-in / press-out button — design spec section 6.
///
/// Tap down  → inset shadow + scale 0.96 over 80ms  (easeOut)
/// Tap up    → raised shadow + scale 1.0  over 150ms (easeOut)
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.width,
    this.height,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  NeumorphicState _surface = NeumorphicState.raised;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1.0);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _press() async {
    if (widget.onPressed == null) return;
    setState(() => _surface = NeumorphicState.inset);
    await _controller.animateTo(
      0.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  Future<void> _release() async {
    if (widget.onPressed == null) return;
    setState(() => _surface = NeumorphicState.raised);
    await _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    widget.onPressed?.call();
  }

  void _cancel() {
    if (widget.onPressed == null) return;
    setState(() => _surface = NeumorphicState.raised);
    _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: NeumorphicContainer(
          state: _surface,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          width: widget.width,
          height: widget.height,
          child: widget.child,
        ),
      ),
    );
  }
}
