import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/fx.dart';
import '../core/theme.dart';

/// Meredupkan ISI kartu kaca (bukan kacanya). Opacity biasa di luar kaca membuat blur
/// hilang selama animasi; ini menjaga blur tetap konsisten.
class GlassDim extends StatelessWidget {
  const GlassDim({super.key, required this.opacity, required this.child});
  final double opacity;
  final Widget child;

  static double of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_DimScope>()?.opacity ?? 1;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: opacity, end: opacity),
        duration: const Duration(milliseconds: 300),
        child: child,
        builder: (_, v, ch) => _DimScope(opacity: v, child: ch!),
      );
}

class _DimScope extends InheritedWidget {
  const _DimScope({required this.opacity, required super.child});
  final double opacity;

  @override
  bool updateShouldNotify(_DimScope old) => old.opacity != opacity;
}

// saturate(180%) seperti CSS
const _sat = <double>[
  1.6296, -0.572, -0.0576, 0, 0,
  -0.1704, 1.228, -0.0576, 0, 0,
  -0.1704, -0.572, 1.7424, 0, 0,
  0, 0, 0, 1, 0,
];

/// Kartu kaca (.gl): blur(26px) saturate(180%), gradient putih transparan,
/// border 16%, highlight atas, bayangan HANYA di luar kartu (seperti CSS box-shadow).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.shadow = true,
    this.contentOpacity = 1,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool shadow;
  final double contentOpacity;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Fx.light, Fx.blur]),
      builder: (ctx, _) {
        final light = Fx.light.value;
        final sigma = light ? math.min(Fx.blur.value, 4.0) : Fx.blur.value;
        final br = BorderRadius.circular(radius);
        final op = (contentOpacity * GlassDim.of(ctx)).clamp(0.0, 1.0).toDouble();
        final ImageFilter? filter = sigma < 0.5
            ? null
            : (light
                ? ImageFilter.blur(sigmaX: sigma, sigmaY: sigma)
                : ImageFilter.compose(
                    outer: const ColorFilter.matrix(_sat),
                    inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  ));
        Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
        if (op < 1) content = Opacity(opacity: op, child: content);
        Widget body = Container(
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
                    content,
                    Positioned(
                      top: 0,
                      left: radius * 0.8,
                      right: radius * 0.8,
                      height: 1,
                      child: const IgnorePointer(child: ColoredBox(color: Color(0x59FFFFFF))),
                    ),
                  ],
                ),
              );
        return CustomPaint(
          painter: (shadow && !light) ? _OuterShadow(radius) : null,
          child: ClipRRect(
            borderRadius: br,
            child: filter == null ? body : BackdropFilter(filter: filter, child: body),
          ),
        );
      },
    );
  }
}

/// box-shadow: 0 12px 40px rgba(0,0,0,.5) yang tidak menembus ke dalam kaca.
class _OuterShadow extends CustomPainter {
  _OuterShadow(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final outer = Path()..addRect(Rect.fromLTRB(-90, -90, size.width + 90, size.height + 150));
    final hole = Path()..addRRect(rr);
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.difference, outer, hole));
    canvas.drawRRect(
      rr.shift(const Offset(0, 12)),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OuterShadow o) => o.radius != radius;
}
