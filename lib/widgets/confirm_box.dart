import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'glass_card.dart';
import 'glow_button.dart';

/// Dialog konfirmasi kaca (pengganti confirmBox di index.php).
/// Return true kalau menekan tombol OK.
Future<bool> confirmBox(
  BuildContext context, {
  required String title,
  required Widget body,
  IconData icon = FontAwesomeIcons.circleQuestion,
  String okLabel = 'Ya',
  IconData? okIcon,
  String cancelLabel = 'Batal',
  bool danger = false,
}) async {
  final r = await showGeneralDialog<bool>(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    body,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GlowButton(
                            kind: BtnKind.dark,
                            label: cancelLabel,
                            expand: true,
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlowButton(
                            kind: danger ? BtnKind.danger : BtnKind.primary,
                            label: okLabel,
                            icon: okIcon,
                            expand: true,
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, a, _, child) => FadeTransition(
      opacity: a,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1)
              .chain(CurveTween(curve: Curves.easeOutBack))
              .animate(a),
          child: child,
        ),
      ),
    ),
  );
  return r ?? false;
}
