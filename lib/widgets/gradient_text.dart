import 'package:flutter/material.dart';

/// Teks dengan gradient (harga emas, judul putih->abu).
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) =>
          gradient.createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}
