import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_card.dart';

/// Dialog kaca serbaguna (isi bebas). Tutup dengan Navigator.pop(context, hasil).
Future<T?> showGlassDialog<T>(BuildContext context, WidgetBuilder builder) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: const Color(0xB3000000),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, _, __) => SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              type: MaterialType.transparency,
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: builder(ctx),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, a, _, child) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1)
              .chain(CurveTween(curve: Curves.easeOutBack))
              .animate(a),
          child: child,
        ),
      ),
  );
}
