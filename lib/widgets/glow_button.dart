import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

enum BtnKind { primary, dark, trash, danger }

class _BtnStyle {
  _BtnStyle({this.gradient, this.color, this.border, required this.fg, this.shadow});
  final Gradient? gradient;
  final Color? color;
  final Border? border;
  final Color fg;
  final List<BoxShadow>? shadow;
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

/// Tombol .btn: gradient, ripple, animasi tekan (scale), percikan partikel.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    this.icon,
    this.label,
    this.onPressed,
    this.kind = BtnKind.primary,
    this.height = 44,
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

class _GlowButtonState extends State<GlowButton> {
  bool _down = false;
  Offset _pos = Offset.zero;

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
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutBack,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              splashColor: w.kind == BtnKind.primary ? Colors.black26 : Colors.white24,
              onTapDown: (d) {
                _pos = d.globalPosition;
                setState(() => _down = true);
              },
              onTapCancel: () => setState(() => _down = false),
              onTap: enabled
                  ? () {
                      setState(() => _down = false);
                      burst(context, _pos);
                      w.onPressed!();
                    }
                  : null,
              child: Padding(padding: w.padding, child: Center(child: content)),
            ),
          ),
        ),
      ),
    );
  }
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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
    final glow = Paint()
      ..color = Color.fromRGBO(255, 255, 255, op * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final dot = Paint()..color = Color.fromRGBO(255, 255, 255, op);
    for (var i = 0; i < d.length; i++) {
      final a = math.pi * 2 * i / d.length;
      final o = pos + Offset(math.cos(a), math.sin(a)) * (d[i] * t);
      final r = 3 * op;
      canvas.drawCircle(o, r * 1.8, glow);
      canvas.drawCircle(o, r, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) => false;
}
