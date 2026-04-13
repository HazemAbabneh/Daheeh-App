import 'package:flutter/material.dart';

/// Wraps any widget with a spring-elastic press animation.
/// Scales down on press (0.88) then bounces back with elasticOut.
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration pressDuration;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressDuration = const Duration(milliseconds: 120),
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) => _ctrl.forward();

  void _up(TapUpDetails _) {
    _ctrl
        .reverse(from: _ctrl.value)
        .then((_) => widget.onTap?.call());
  }

  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:    _down,
      onTapUp:      _up,
      onTapCancel:  _cancel,
      onLongPress:  widget.onLongPress,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
