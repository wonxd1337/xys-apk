import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/fx.dart';

/// Muncul pelan: naik + membesar sedikit. TANPA fade (fade membuat blur kaca hilang
/// selama animasi). Bertahap berdasarkan [index], diputar sekali. Mati di mode ringan.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0, this.dy = 22, this.baseDelay = 0});
  final Widget child;
  final int index;
  final double dy;
  final int baseDelay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: const Cubic(0.2, 0.9, 0.2, 1));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final int d = widget.baseDelay + 40 * math.min<int>(widget.index, 12);
    if (Fx.light.value) {
      _c.value = 1;
    } else if (d == 0) {
      _c.forward();
    } else {
      _t = Timer(Duration(milliseconds: d), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) {
        final v = _a.value.clamp(0.0, 1.0).toDouble();
        return Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..translate(0.0, widget.dy * (1 - v))
            ..scale(0.97 + 0.03 * v),
          child: child,
        );
      },
    );
  }
}

/// Animasi masuk saat halaman (menu) menjadi aktif: meluncur kecil, tanpa fade.
class ViewEntrance extends StatefulWidget {
  const ViewEntrance({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<ViewEntrance> createState() => _ViewEntranceState();
}

class _ViewEntranceState extends State<ViewEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant ViewEntrance old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !Fx.light.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
          .animate(CurvedAnimation(parent: _c, curve: const Cubic(0.2, 0.9, 0.2, 1))),
      child: widget.child,
    );
  }
}
