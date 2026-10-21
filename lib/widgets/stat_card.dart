import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import 'glass_card.dart';

/// Angka yang menghitung naik (animasi 750 ms).
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style});
  final num value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text(fmt(v), style: style),
      );
}

const statValueStyle = TextStyle(fontSize: 16.8, fontWeight: FontWeight.w800, height: 1.2);

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.bar});
  final IconData icon;
  final String label;
  final Widget value;
  final double? bar; // 0..1

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFF8A8A8A)],
              ),
              boxShadow: const [BoxShadow(color: Color(0x44FFFFFF), blurRadius: 24)],
            ),
            child: Icon(icon, size: 15, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: C.muted, fontSize: 10.9)),
                value,
                if (bar != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        height: 5,
                        color: const Color(0x33FFFFFF),
                        child: AnimatedFractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: bar!.clamp(0.0, 1.0).toDouble(),
                          duration: const Duration(milliseconds: 900),
                          curve: const Cubic(0.2, 0.9, 0.2, 1),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Color(0xFF666666), Colors.white]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
