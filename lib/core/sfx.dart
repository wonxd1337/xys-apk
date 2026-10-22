import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Suara klik / berhasil / gagal. Bisa dimatikan dari menu Pengaturan.
class Sfx {
  static bool enabled = true;
  static final AudioPlayer _p = AudioPlayer();
  static bool _ready = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool('sfx') ?? true;
    try {
      await _p.setPlayerMode(PlayerMode.lowLatency);
      await _p.setReleaseMode(ReleaseMode.stop);
      _ready = true;
    } catch (_) {}
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('sfx', v);
  }

  static void _play(String f, double vol) {
    if (!enabled || !_ready) return;
    try {
      _p.play(AssetSource('sounds/$f'), volume: vol).catchError((_) {});
    } catch (_) {}
  }

  static void click() => _play('click.wav', 0.55);
  static void ok() => _play('ok.wav', 0.5);
  static void err() => _play('err.wav', 0.55);

  /// bunyi sesuai jenis toast
  static void toast(IconData icon) {
    if (icon == FontAwesomeIcons.triangleExclamation ||
        icon == FontAwesomeIcons.circleExclamation) {
      err();
    } else {
      ok();
    }
  }
}
