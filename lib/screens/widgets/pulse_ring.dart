// widgets/pulse_ring.dart
import 'package:flutter/material.dart';

class PulseRing extends StatefulWidget {
  final Widget child;
  final bool active;
  final Color color;
  final double size;

  const PulseRing({
    super.key,
    required this.child,
    required this.active,
    required this.color,
    this.size = 80,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale =
        Tween<double>(begin: 1.0, end: 1.7).animate(_ctrl);
    _opacity =
        Tween<double>(begin: 0.6, end: 0.0).animate(_ctrl);
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(PulseRing old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: _opacity.value),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: widget.size * 0.72,
            height: widget.size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.1),
              border: Border.all(
                  color: widget.color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: widget.active
                  ? [
                BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    blurRadius: 12)
              ]
                  : null,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
