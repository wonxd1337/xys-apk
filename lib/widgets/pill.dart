import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Lencana kecil (.bd): ikon + teks. [gold] untuk harga.
class Pill extends StatelessWidget {
  const Pill(this.icon, this.text, {super.key, this.gold = false, this.color});
  final IconData? icon;
  final String text;
  final bool gold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (gold ? const Color(0xFFFFD24A) : const Color(0xFFD4D4D8));
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: gold ? const Color(0x21FFC400) : const Color(0x1AFFFFFF),
        border: Border.all(color: gold ? const Color(0x73FFC400) : const Color(0x33FFFFFF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 10, color: fg), const SizedBox(width: 6)],
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
        ),
      ]),
    );
  }
}
