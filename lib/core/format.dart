import 'package:flutter/material.dart';

/// 1234567 -> 1.234.567 (format id-ID)
String fmt(num? n) {
  final v = (n ?? 0).round();
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return (v < 0 ? '-' : '') + b.toString();
}

/// Berat ringkas: >=1jt -> M, >=1rb -> K, kecil dipotong 2 desimal
String fw(num w) {
  String c(double v, bool trim) {
    var s = ((v * 100 + 1e-9).floor() / 100).toStringAsFixed(2);
    if (trim) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s;
  }

  final d = w.toDouble();
  final t = d >= 1e6
      ? '${c(d / 1e6, true)}M'
      : d >= 1e3
          ? '${c(d / 1e3, true)}K'
          : c(d, false);
  return '$t kg';
}

/// detik -> "5d", "3m", "2j", "1h"
String ago(int? n) {
  if (n == null) return '';
  if (n < 60) return '${n}d';
  if (n < 3600) return '${n ~/ 60}m';
  if (n < 86400) return '${n ~/ 3600}j';
  return '${n ~/ 86400}h';
}

/// Warna mutasi Roblox: "t r g b 0 t r g b 0 ..." (nilai 0..1)
class MutStop {
  const MutStop(this.color, this.t);
  final Color color;
  final double t;
}

List<MutStop> parseMutationColor(String? c) {
  if (c == null || c.trim().isEmpty) return [];
  final p = c.trim().split(RegExp(r'\s+'));
  final s = <MutStop>[];
  for (var i = 0; i + 3 < p.length; i += 5) {
    int x(int j) =>
        (((double.tryParse(p[i + j]) ?? 0) * 255).round().clamp(0, 255)).toInt();
    final t = (double.tryParse(p[i]) ?? 0).clamp(0.0, 1.0).toDouble();
    s.add(MutStop(Color.fromARGB(255, x(1), x(2), x(3)), t));
  }
  if (s.length == 1) s.add(s.first);
  return s;
}

LinearGradient mutationGradient(List<MutStop> s, {int alpha = 255}) =>
    LinearGradient(
      colors: s.map((k) => k.color.withAlpha(alpha)).toList(),
      stops: s.map((k) => k.t).toList(),
    );

/// Warna katalog bisa berupa daftar hex ("#ff0000,#00ff00") atau format dashboard;
/// keduanya dikonversi ke format dashboard "t r g b 0 ...".
String catalogColorToMut(String? c) {
  final hs = (c ?? '')
      .split(',')
      .map((x) => x.trim().replaceFirst('#', ''))
      .where((x) => RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(x))
      .toList();
  if (hs.isEmpty) return c ?? '';
  String v(String h, int j) =>
      (int.parse(h.substring(2 * j, 2 * j + 2), radix: 16) / 255).toStringAsFixed(4);
  final out = <String>[];
  for (var i = 0; i < hs.length; i++) {
    final t = hs.length > 1 ? i / (hs.length - 1) : 0.0;
    out.add('$t ${v(hs[i], 0)} ${v(hs[i], 1)} ${v(hs[i], 2)} 0');
  }
  return out.join(' ');
}
