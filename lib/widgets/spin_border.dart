import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Border conic-gradient yang berputar + glow (efek :active pada kartu).
class SpinBorder extends StatefulWidget {
  const SpinBorder({
    super.key,
    required this.child,
    required this.color,
    this.active = false,
    this.radius = 20,
  });

  final Widget child;
  final Color color;
  final bool active;
  final double radius;

  @override
  State<SpinBorder> createState() => _SpinBorderState();
}

class _SpinBorderState extends State<SpinBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant SpinBorder old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(widget.radius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: widget.active
            ? [
                BoxShadow(
                  color: widget.color.withAlpha(90),
                  blurRadius: 36,
                  spreadRadius: -6,
                ),
              ]
            : const [],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: widget.active ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => CustomPaint(
                    painter: _BorderPainter(
                      _c.value * 2 * math.pi,
                      widget.color,
                      widget.radius,
                    ),
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

class _BorderPainter extends CustomPainter {
  _BorderPainter(this.angle, this.color, this.radius);
  final double angle;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        colors: [Colors.transparent, color, Colors.transparent, Colors.transparent],
        stops: const [0, 0.18, 0.38, 1],
        transform: GradientRotation(angle),
      ).createShader(rect);
    canvas.drawRRect(rr, p);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter o) =>
      o.angle != angle || o.color != color;
}
