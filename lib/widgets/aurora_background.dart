import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Latar Aurora: gradient radial gelap, gambar hitam-putih (Ken Burns),
/// overlay gelap di kiri/bawah, dan partikel naik.
/// Gambar: taruh di assets/images/bg.jpg (opsional).
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.image = const AssetImage('assets/images/bg.jpg'),
  });

  final Widget child;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.7, -1.0),
                radius: 1.25,
                colors: [Color(0xFF303034), Color(0xFF0C0C0D), Colors.black],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
        ),
        if (image != null) Positioned.fill(child: _KenBurns(image: image!)),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black, Color(0xBB000000), Colors.transparent],
                  stops: [0, 0.3, 0.75],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xAA000000), Colors.transparent],
                  stops: [0, 0.4],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: _Particles()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _KenBurns extends StatefulWidget {
  const _KenBurns({required this.image});
  final ImageProvider image;

  @override
  State<_KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<_KenBurns> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))
        ..repeat(reverse: true);

  // grayscale + contrast 1.15
  static const _m = <double>[
    0.2126 * 1.15, 0.7152 * 1.15, 0.0722 * 1.15, 0, -19.1,
    0.2126 * 1.15, 0.7152 * 1.15, 0.0722 * 1.15, 0, -19.1,
    0.2126 * 1.15, 0.7152 * 1.15, 0.0722 * 1.15, 0, -19.1,
    0, 0, 0, 1, 0,
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 1 + 0.12 * t,
            child: FractionalTranslation(translation: Offset(-0.02 * t, 0), child: child),
          );
        },
        child: Opacity(
          opacity: 0.5,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(_m),
            child: Image(
              image: widget.image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _P {
  _P(this.x, this.y, this.r, this.v, this.a);
  double x, y;
  final double r, v, a;
}

class _Particles extends StatefulWidget {
  const _Particles();

  @override
  State<_Particles> createState() => _ParticlesState();
}

class _ParticlesState extends State<_Particles> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final List<_P> _ps = [];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: IgnorePointer(
          child: CustomPaint(size: Size.infinite, painter: _PP(_c, _ps)),
        ),
      );
}

class _PP extends CustomPainter {
  _PP(this.c, this.ps) : super(repaint: c);
  final AnimationController c;
  final List<_P> ps;
  final _rnd = math.Random();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (ps.isEmpty) {
      for (var i = 0; i < 70; i++) {
        ps.add(_P(_rnd.nextDouble() * size.width, _rnd.nextDouble() * size.height,
            _rnd.nextDouble() * 2 + 0.4, _rnd.nextDouble() * 0.6 + 0.2, _rnd.nextDouble() * 6));
      }
    }
    final paint = Paint();
    for (final p in ps) {
      p.y -= p.v;
      p.x += math.sin(p.y / 60 + p.a) * 0.3;
      if (p.y < -5) {
        p.y = size.height + 5;
        p.x = _rnd.nextDouble() * size.width;
      }
      final op = (0.12 + 0.5 * math.sin(p.y / 90 + p.a).abs()).clamp(0.0, 1.0).toDouble();
      paint.color = Color.fromRGBO(255, 255, 255, op);
      canvas.drawCircle(Offset(p.x, p.y), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PP o) => false;
}
