import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode efek. Penuh = kaca blur 26 + saturasi 180% (sama dengan dashboard web),
/// latar bergerak + partikel. Ringan = kaca blur lebih kecil tanpa efek bergerak
/// (untuk HP yang terasa patah-patah).
class Fx {
  static final ValueNotifier<bool> light = ValueNotifier(false);
  /// kekuatan blur kaca (sigma). 0 = bening penuh, 26 = sama dengan CSS asli.
  static final ValueNotifier<double> blur = ValueNotifier(5);
  /// detak latar (~25 fps) dipakai bersama oleh latar, partikel, dan titik status
  static final ValueNotifier<int> tick = ValueNotifier(0);
  static final Stopwatch clock = Stopwatch()..start();

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    light.value = p.getBool('fx_light') ?? false;
    blur.value = p.getDouble('fx_blur') ?? 5;
  }

  static Future<void> setBlur(double v) async {
    blur.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('fx_blur', v);
  }

  static Future<void> setLight(bool v) async {
    light.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('fx_light', v);
  }
}
