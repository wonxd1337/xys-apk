import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'gradient_text.dart';

class PageTitle extends StatelessWidget {
  const PageTitle(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
        child: Row(children: [
          Icon(icon, size: 16),
          const SizedBox(width: 9),
          GradientText(text,
              gradient: titleGradient,
              style: const TextStyle(fontSize: 17.6, fontWeight: FontWeight.w800)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 10),
        child: Column(children: [
          Icon(icon, size: 38, color: const Color(0x99FFFFFF)),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, height: 1.4)),
        ]),
      );
}
