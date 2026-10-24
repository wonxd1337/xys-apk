import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/fx.dart';

/// Latar Aurora yang ringan:
///  - gambar di-decode kecil sekali, dijadikan hitam-putih sekali (bukan filter tiap frame),
///  - Ken Burns + partikel digambar langsung di canvas (tanpa saveLayer), ~25 fps,
///  - berhenti otomatis saat app tidak aktif atau mode ringan.
/// Gambar dicari di assets/images/ (prioritas: image.*, lalu bg.*, lalu file pertama).
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _P {
  const _P(this.x, this.y, this.v, this.a);
  final double x, y, v, a;
}

class _AuroraBackgroundState extends State<AuroraBackground> with WidgetsBindingObserver {
  ui.Image? _img;
  Timer? _timer;
  bool _resumed = true;
  late final List<List<_P>> _groups = () {
    final r = math.Random(7);
    return List.generate(3, (g) => List.generate(14, (_) => _P(r.nextDouble(), r.nextDouble(), 0.006 + r.nextDouble() * 0.012 + g * 0.004, r.nextDouble() * 6)));
  }();

  // grayscale + contrast 1.15 (dipanggang sekali)
  static const _m = <double>[
    0.2126 * 1.15, 0.7152 * 1.15, 0.0722 * 1.15, 0, -19.1,
    0.2126 * 1.15, 0.7152 * 1.15, 0.0722 * 1.15, 0, -19.1,
    0.2126 * 1.15, 0.7152 * 1.15, 0.0722 * 1.15, 0, -19.1,
    0, 0, 0, 1, 0,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Fx.light.addListener(_sync);
    _loadImage();
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Fx.light.removeListener(_sync);
    _timer?.cancel();
    _img?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }

  bool get _motion =>
      _resumed &&
      !Fx.light.value &&
      !WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (_motion) {
      _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => Fx.tick.value++);
    } else {
      Fx.tick.value++; // gambar satu frame diam
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadImage() async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      final all = m
          .listAssets()
          .where((a) =>
              a.startsWith('assets/images/') &&
              RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false).hasMatch(a))
          .toList()
        ..sort();
      if (all.isEmpty) return;
      String name(String a) => a.split('/').last.toLowerCase();
      final pick = all.firstWhere(
        (a) => name(a).startsWith('image.'),
        orElse: () => all.firstWhere((a) => name(a).startsWith('bg.'), orElse: () => all.first),
      );
      final data = await rootBundle.load(pick);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 1000);
      final frame = await codec.getNextFrame();
      final src = frame.image;
      final rec = ui.PictureRecorder();
      Canvas(rec).drawImage(src, Offset.zero, Paint()..colorFilter = const ColorFilter.matrix(_m));
      final baked = await rec.endRecording().toImage(src.width, src.height);
      src.dispose();
      if (!mounted) {
        baked.dispose();
        return;
      }
      setState(() => _img = baked);
      Fx.tick.value++;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 700;
    final motion = _motion;
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.7, -1.0),
                  radius: 1.25,
                  colors: [Color(0xFF303034), Color(0xFF0C0C0D), Colors.black],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),
          ),
        ),
        if (_img != null)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ImagePainter(_img!, Fx.tick, Fx.clock, motion, narrow ? 0.62 : 0.5),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: narrow
                      ? const [Color(0x99000000), Color(0x40000000), Colors.transparent]
                      : const [Colors.black, Color(0xBB000000), Colors.transparent],
                  stops: const [0, 0.3, 0.75],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(narrow ? 0x88000000 : 0xAA000000), Colors.transparent],
                  stops: const [0, 0.4],
                ),
              ),
            ),
          ),
        ),
        if (motion)
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(painter: _ParticlePainter(_groups, Fx.tick, Fx.clock)),
              ),
            ),
          ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.img, Listenable tick, this.sw, this.motion, this.opacity) : super(repaint: tick);
  final ui.Image img;
  final Stopwatch sw;
  final bool motion;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    double k = 0;
    if (motion) {
      final p = (sw.elapsedMilliseconds / 1000 / 26) % 2;
      k = Curves.easeInOut.transform(p < 1 ? p : 2 - p);
    }
    final ia = img.width / img.height, da = size.width / size.height;
    double w, h;
    if (ia > da) {
      h = img.height.toDouble();
      w = h * da;
    } else {
      w = img.width.toDouble();
      h = w / da;
    }
    final src = Rect.fromLTWH((img.width - w) / 2, (img.height - h) / 2, w, h);
    canvas.save();
    canvas.translate(size.width / 2 - 0.02 * k * size.width, size.height / 2);
    canvas.scale(1 + 0.12 * k);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawImageRect(
      img,
      src,
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ImagePainter o) =>
      o.img != img || o.motion != motion || o.opacity != opacity;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.groups, Listenable tick, this.sw) : super(repaint: tick);
  final List<List<_P>> groups;
  final Stopwatch sw;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = sw.elapsedMilliseconds / 1000;
    final paint = Paint()..strokeCap = StrokeCap.round;
    const widths = [1.6, 2.6, 3.6];
    for (var g = 0; g < groups.length; g++) {
      final pts = <Offset>[];
      for (final p in groups[g]) {
        final y = ((p.y - p.v * s) % 1.0 + 1.0) % 1.0;
        final x = p.x + 0.02 * math.sin(y * 18 + p.a);
        pts.add(Offset(x * size.width, y * size.height));
      }
      paint
        ..strokeWidth = widths[g]
        ..color = Color.fromRGBO(255, 255, 255, 0.16 + 0.4 * ((math.sin(s * 0.9 + g * 2.1) + 1) / 2));
      canvas.drawPoints(ui.PointMode.points, pts, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter o) => false;
}
