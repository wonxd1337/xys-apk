import 'package:flutter/material.dart';
import '../core/sfx.dart';
import '../core/theme.dart';

/// Saklar (.swt): putih menyala saat aktif.
class GlassSwitch extends StatelessWidget {
  const GlassSwitch({super.key, required this.value, required this.onChanged, this.large = false});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final w = large ? 58.0 : 46.0, h = large ? 32.0 : 26.0, k = h - 6;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null
          ? null
          : () {
              Sfx.click();
              onChanged!(!value);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: w,
        height: h,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: value
              ? const LinearGradient(colors: [Colors.white, Color(0xFFBDBDBD)])
              : null,
          color: value ? null : const Color(0x1FFFFFFF),
          border: Border.all(color: C.glassBorder),
          boxShadow: value ? const [BoxShadow(color: Color(0x55FFFFFF), blurRadius: 16)] : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: k,
            height: k,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.black : const Color(0xB3FFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
