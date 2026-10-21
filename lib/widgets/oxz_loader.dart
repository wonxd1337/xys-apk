import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Animasi loading "OXZ": huruf berombak + cincin berputar + glow.
class OxzLoader extends StatefulWidget {
  const OxzLoader({super.key, this.label = 'Memuat...'});
  final String? label;

  @override
  State<OxzLoader> createState() => _OxzLoaderState();
}

class _OxzLoaderState extends State<OxzLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _letter(String ch, int i, double t) {
    final s = (math.sin(t * 2 * math.pi - i * 0.9) + 1) / 2;
    return Transform.translate(
      offset: Offset(0, -7 * s),
      child: Text(
        ch,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: 5,
          color: Color.fromRGBO(255, 255, 255, 0.55 + 0.45 * s),
          shadows: [Shadow(color: Color.fromRGBO(255, 255, 255, 0.75 * s), blurRadius: 20)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: const Size(160, 160), painter: _RingPainter(t)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (var i = 0; i < 3; i++) _letter('OXZ'[i], i, t)],
                  ),
                ],
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 14),
              Text(widget.label!,
                  style: const TextStyle(color: C.muted, fontSize: 12.5, letterSpacing: 1)),
            ],
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x14FFFFFF);
    canvas.drawCircle(c, 70, base);

    Paint arc(double r, double w, double a, double rot) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          const Color(0x00FFFFFF),
          Color.fromRGBO(255, 255, 255, a),
          const Color(0x00FFFFFF),
        ],
        stops: const [0, 0.3, 0.6],
        transform: GradientRotation(rot),
      ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawCircle(c, 70, arc(70, 2.4, 1, t * 2 * math.pi));
    canvas.drawCircle(c, 58, arc(58, 1.6, 0.45, -t * 2 * math.pi * 1.3));
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.t != t;
}

/// Layar pembuka: tampil saat app dibuka sampai data pertama siap.
class OxzSplash extends StatelessWidget {
  const OxzSplash({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.7, -1.0),
              radius: 1.25,
              colors: [Color(0xFF303034), Color(0xFF0C0C0D), Colors.black],
              stops: [0, 0.48, 1],
            ),
          ),
          child: Center(child: OxzLoader()),
        ),
      );
}
