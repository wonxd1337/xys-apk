import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Muncul pelan: naik + memudar. Bertahap berdasarkan [index].
/// Hanya diputar sekali (saat widget pertama kali dibuat).
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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: const Cubic(0.2, 0.9, 0.2, 1));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final d = widget.baseDelay + 45 * math.min(widget.index, 12);
    if (d == 0) {
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
        if (v >= 1) return child!;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, widget.dy * (1 - v)), child: child),
        );
      },
    );
  }
}

/// Animasi masuk saat halaman (tab menu) menjadi aktif.
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
    duration: const Duration(milliseconds: 480),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant ViewEntrance old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: const Cubic(0.2, 0.9, 0.2, 1))),
        child: widget.child,
      ),
    );
  }
}
