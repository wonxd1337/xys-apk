import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/fx.dart';
import '../core/sfx.dart';
import '../core/theme.dart';

enum BtnKind { primary, dark, trash, danger }

class _BtnStyle {
  _BtnStyle({this.gradient, this.color, this.border, required this.fg, this.shadow, this.sheen = 1, this.topLine = false});
  final Gradient? gradient;
  final Color? color;
  final Border? border;
  final Color fg;
  final List<BoxShadow>? shadow;
  final double sheen; // kekuatan kilau yang menyapu (::before)
  final bool topLine; // inset 0 1px 0 #fff
}

_BtnStyle _styleOf(BtnKind k) {
  switch (k) {
    case BtnKind.primary:
      return _BtnStyle(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFBDBDBD)],
        ),
        fg: Colors.black,
        topLine: true,
        shadow: const [BoxShadow(color: Color(0x2EFFFFFF), blurRadius: 18, offset: Offset(0, 6))],
      );
    case BtnKind.dark:
      return _BtnStyle(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A4A4A), Color(0xFF141414)],
        ),
        border: Border.all(color: C.glassBorder),
        fg: Colors.white,
        sheen: 0.25,
        shadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 6))],
      );
    case BtnKind.trash:
      return _BtnStyle(
        color: const Color(0x24EF4444),
        border: Border.all(color: const Color(0x80EF4444)),
        fg: const Color(0xFFFF5A5A),
      );
    case BtnKind.danger:
      return _BtnStyle(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
        ),
        fg: Colors.white,
        shadow: const [BoxShadow(color: Color(0x44EF4444), blurRadius: 18, offset: Offset(0, 6))],
      );
  }
}

/// Tombol .btn: gradient, kilau menyapu, tekan mengecil (.9) lalu memantul, percikan partikel.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    this.icon,
    this.label,
    this.onPressed,
    this.kind = BtnKind.primary,
    this.height = 40,
    this.width,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.radius = 15,
  });

  final IconData? icon;
  final String? label;
  final VoidCallback? onPressed; // null = nonaktif
  final BtnKind kind;
  final double height;
  final double? width;
  final bool expand;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> with SingleTickerProviderStateMixin {
  bool _down = false;
  Offset _pos = Offset.zero;
  late final AnimationController _sheen =
      AnimationController(
        vsync: this,
        animationBehavior: AnimationBehavior.preserve, duration: const Duration(milliseconds: 650));

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = _styleOf(widget.kind);
    final br = BorderRadius.circular(widget.radius);
    final enabled = widget.onPressed != null;
    final w = widget;

    final content = Row(
      mainAxisSize: w.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (w.icon != null) Icon(w.icon, size: 14, color: st.fg),
        if (w.icon != null && w.label != null) const SizedBox(width: 8),
        if (w.label != null)
          Flexible(
            child: Text(
              w.label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: st.fg, fontSize: 14.4, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: Duration(milliseconds: _down ? 80 : 260),
        curve: _down ? Curves.easeOut : const Cubic(0.34, 1.8, 0.5, 1),
        child: Container(
          height: w.height,
          width: w.width,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: st.gradient,
            color: st.color,
            border: st.border,
            boxShadow: st.shadow,
          ),
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: br,
                    splashColor: w.kind == BtnKind.primary ? Colors.black12 : Colors.white12,
                    highlightColor: Colors.transparent,
                    onTapDown: (d) {
                      _pos = d.globalPosition;
                      setState(() => _down = true);
                    },
                    onTapCancel: () => setState(() => _down = false),
                    onTap: enabled
                        ? () {
                            setState(() => _down = false);
                            Sfx.click();
                            if (!Fx.light.value) {
                              _sheen.forward(from: 0);
                              burst(context, _pos);
                            }
                            w.onPressed!();
                          }
                        : null,
                    child: Padding(padding: w.padding, child: Center(child: content)),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(child: CustomPaint(painter: _SheenPainter(_sheen, st.sheen))),
                ),
                if (st.topLine)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 1,
                    child: IgnorePointer(child: ColoredBox(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kilau diagonal yang menyapu kiri ke kanan (btn::before).
class _SheenPainter extends CustomPainter {
  _SheenPainter(this.c, this.strength) : super(repaint: c);
  final AnimationController c;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (c.value <= 0 || c.value >= 1) return;
    final t = Curves.ease.transform(c.value);
    final dx = (t * 2.6 - 1.3) * size.width;
    final rect = Offset(dx, 0) & size;
    final shader = LinearGradient(
      begin: const Alignment(-1, -0.35),
      end: const Alignment(1, 0.35),
      colors: [
        const Color(0x00FFFFFF),
        Color.fromRGBO(255, 255, 255, 0.85 * strength),
        const Color(0x00FFFFFF),
      ],
      stops: const [0.3, 0.5, 0.7],
    ).createShader(rect);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _SheenPainter o) => false;
}

/// Percikan 10 partikel putih dari titik sentuh.
void burst(BuildContext context, Offset pos) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => _Burst(pos: pos, onDone: () => e.remove()));
  overlay.insert(e);
}

class _Burst extends StatefulWidget {
  const _Burst({required this.pos, required this.onDone});
  final Offset pos;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        animationBehavior: AnimationBehavior.preserve, duration: const Duration(milliseconds: 600));
  final _rnd = math.Random();
  late final List<double> _d = List.generate(10, (_) => 28 + _rnd.nextDouble() * 34);

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(size: Size.infinite, painter: _BurstPainter(_c, widget.pos, _d)),
      );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.c, this.pos, this.d) : super(repaint: c);
  final AnimationController c;
  final Offset pos;
  final List<double> d;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(c.value);
    final op = (1 - c.value).clamp(0.0, 1.0).toDouble();
    final dot = Paint()..color = Color.fromRGBO(255, 255, 255, op);
    final glow = Paint()..color = Color.fromRGBO(255, 255, 255, op * 0.35);
    for (var i = 0; i < d.length; i++) {
      final a = math.pi * 2 * i / d.length;
      final o = pos + Offset(math.cos(a), math.sin(a)) * (d[i] * t);
      final r = 3 * op;
      canvas.drawCircle(o, r * 2.2, glow);
      canvas.drawCircle(o, r, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) => false;
}
