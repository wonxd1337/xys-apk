import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Kartu kaca (.gl): blur + gradient putih transparan + border + highlight atas.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.sigma = 13,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double sigma;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br,
              border: Border.all(color: C.glassBorder),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x21FFFFFF), Color(0x0AFFFFFF)],
              ),
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Padding(padding: padding ?? EdgeInsets.zero, child: child),
                Positioned(
                  top: 0,
                  left: radius,
                  right: radius,
                  height: 1,
                  child: const IgnorePointer(
                    child: ColoredBox(color: Color(0x59FFFFFF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
