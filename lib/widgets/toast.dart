import 'package:flutter/material.dart';
import '../core/fa.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/sfx.dart';
import 'glass_card.dart';

/// Toast pil kaca di bawah layar (muncul memantul, hilang setelah ~2.6 dtk).
void showToast(BuildContext context, String msg,
    {IconData icon = FaS.circleCheck}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  Sfx.toast(icon);
  late OverlayEntry e;
  e = OverlayEntry(
    builder: (_) => _Toast(msg: msg, icon: icon, onDone: () => e.remove()),
  );
  overlay.insert(e);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.msg, required this.icon, required this.onDone});
  final String msg;
  final IconData icon;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
        vsync: this,
        animationBehavior: AnimationBehavior.preserve,
    duration: const Duration(milliseconds: 500),
    reverseDuration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      await _c.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 22;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final t = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0).toDouble());
              return Transform.translate(
                offset: Offset(0, 30 * (1 - t)),
                child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: GlassCard(
                radius: 99,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 15, color: Colors.white),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.msg,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
