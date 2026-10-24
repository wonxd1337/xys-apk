import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/api.dart';
import '../core/fa.dart';
import '../core/fx.dart';
import '../core/sfx.dart';
import '../core/theme.dart';
import '../state/dash_state.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/oxz_loader.dart';
import 'dashboard_view.dart';
import '../widgets/reveal.dart';
import 'find_view.dart';
import 'history_view.dart';
import 'queue_view.dart';
import 'settings_view.dart';
import 'showcase_view.dart';
import 'webhook_view.dart';

enum AppView { dash, queue, hist, wh, find, show, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _drawer = false;
  // geser buka/tutup: 0.55s cubic-bezier(.2,.9,.2,1) seperti #dr di dashboard asli
  late final AnimationController _dc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final Animation<double> _dcT = CurvedAnimation(parent: _dc, curve: const Cubic(0.2, 0.9, 0.2, 1));

  void _setDrawer(bool v) {
    if (_drawer == v) return;
    setState(() => _drawer = v);
    if (v) {
      _dc.forward();
    } else {
      _dc.reverse();
    }
  }

  bool _splash = true;
  bool _minDone = false;
  late AppView _view = Api.baseUrl.isEmpty ? AppView.settings : AppView.dash;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    dash.start();
    dash.addListener(_checkSplash);
    Future.delayed(const Duration(milliseconds: 1800), () {
      _minDone = true;
      _checkSplash();
    });
  }

  void _checkSplash() {
    if (!_splash || !_minDone || !mounted) return;
    if (Api.baseUrl.isEmpty || dash.loaded || dash.error != null) {
      setState(() => _splash = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dc.dispose();
    dash.removeListener(_checkSplash);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    dash.setPaused(state != AppLifecycleState.resumed);
  }

  Color _stColor(String? s) {
    switch (s) {
      case 'online':
        return C.green;
      case 'hopping':
        return C.amber;
      case 'offline':
        return C.red;
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _go(AppView v) {
    setState(() {
      _view = v;
      _drawer = false;
    });
    _dc.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(children: [
        AuroraBackground(
        child: PopScope(
          canPop: !_drawer && _view == AppView.dash,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_drawer) {
              _setDrawer(false);
            } else {
              setState(() => _view = AppView.dash);
            }
          },
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    Reveal(dy: -24, child: _header(w)),
                    Expanded(
                      child: IndexedStack(
                        index: _view.index,
                        children: [
                          ViewEntrance(
                              active: _view == AppView.dash, child: const DashboardView()),
                          ViewEntrance(
                              active: _view == AppView.queue, child: const QueueView()),
                          ViewEntrance(
                              active: _view == AppView.hist, child: const HistoryView()),
                          ViewEntrance(
                              active: _view == AppView.wh,
                              child: WebhookView(active: _view == AppView.wh)),
                          ViewEntrance(
                              active: _view == AppView.find,
                              child: FindView(
                                  active: _view == AppView.find,
                                  onGoWebhook: () => _go(AppView.wh))),
                          ViewEntrance(
                              active: _view == AppView.show,
                              child: ShowcaseView(active: _view == AppView.show)),
                          ViewEntrance(
                              active: _view == AppView.settings,
                              child: SettingsView(onSaved: () => _go(AppView.dash))),
                        ],
                      ),
                    ),
                  ],
                ),
                _scrim(),
                _drawerPanel(w),
              ],
            ),
          ),
        ),
      ),
        _splashLayer(),
      ]),
    );
  }

  Widget _splashLayer() => Positioned.fill(
        child: IgnorePointer(
          ignoring: !_splash,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _splash
                ? const OxzSplash(key: ValueKey('splash'))
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ),
      );

  Widget _soon(IconData icon, String title) => Center(
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 6),
              const Text('Tersedia di tahap 4', style: TextStyle(color: C.muted)),
            ],
          ),
        ),
      );

  // ---------- header ----------
  Widget _header(double w) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: ListenableBuilder(
          listenable: dash,
          builder: (_, __) => Row(
            children: [
              _Hamburger(open: _drawer, onTap: () => _setDrawer(!_drawer)),
              const SizedBox(width: 10),
              const Icon(FontAwesomeIcons.skull, size: 18),
              if (w > 700) ...[
                const SizedBox(width: 10),
                const Text('Deoxys Umbreon',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _live(),
                      const SizedBox(width: 8),
                      Flexible(child: _botMenu()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _live() {
    final s = dash;
    final Color c;
    final String t;
    final bool pulse;
    if (!s.connected) {
      c = _stColor(null);
      t = 'TERPUTUS';
      pulse = false;
    } else {
      c = _stColor(s.bot.status);
      t = s.bot.status == 'online'
          ? 'ONLINE'
          : (s.bot.status == 'hopping' ? 'HOPPING' : 'OFFLINE');
      pulse = s.bot.status != 'offline';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: c.withAlpha(0x1F),
        border: Border.all(color: c.withAlpha(0x66)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _PulseDot(color: c, pulse: pulse),
        const SizedBox(width: 7),
        Text(t,
            style: TextStyle(
                color: c, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      ]),
    );
  }

  Widget _botMenu() {
    final s = dash;
    final label = s.user.isEmpty ? 'Pilih bot' : s.user;
    return PopupMenuButton<String>(
      onSelected: dash.selectUser,
      color: const Color(0xF7121214),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: C.glassBorder),
      ),
      offset: const Offset(0, 48),
      itemBuilder: (_) => s.users.isEmpty
          ? [
              const PopupMenuItem<String>(
                enabled: false,
                child: Text('Belum ada bot terdaftar', style: TextStyle(color: C.muted)),
              ),
            ]
          : s.users
              .map((n) => PopupMenuItem<String>(
                    value: n,
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: _stColor(s.bots[n]?.status)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(n, overflow: TextOverflow.ellipsis)),
                      if (n == s.user) const Icon(FontAwesomeIcons.check, size: 12),
                    ]),
                  ))
              .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.glassBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _stColor(s.bot.status)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.8)),
          ),
          const SizedBox(width: 8),
          const Icon(FontAwesomeIcons.chevronDown, size: 10, color: C.muted),
        ]),
      ),
    );
  }

  // ---------- drawer ----------
  Widget _drawerPanel(double w) {
    final dw = (w * 0.84).clamp(0.0, 290.0).toDouble();
    return Positioned(
      top: 12,
      bottom: 12,
      left: 12,
      width: dw,
      child: AnimatedBuilder(
        animation: _dcT,
        builder: (_, child) => Transform.translate(
          offset: Offset(-1.15 * dw * (1 - _dcT.value), 0),
          child: child,
        ),
        child: IgnorePointer(
          ignoring: !_drawer,
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFF7A7A7A)],
                      ),
                    ),
                    child: const Icon(FontAwesomeIcons.skull, size: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Preman Plaza',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  ),
                ]),
                const SizedBox(height: 22),
                _nav(AppView.dash, FontAwesomeIcons.gaugeHigh, 'Dashboard'),
                _nav(AppView.queue, FontAwesomeIcons.bagShopping, 'Antrian Jual',
                    badge: dash.queue.length),
                _nav(AppView.hist, FontAwesomeIcons.clockRotateLeft, 'Riwayat Penjualan'),
                _nav(AppView.wh, FontAwesomeIcons.discord, 'Webhook'),
                _nav(AppView.find, FontAwesomeIcons.magnifyingGlass, 'Find Items'),
                _nav(AppView.show, FaS.star, 'Showcase Item'),
                const Spacer(),
                _nav(AppView.settings, FontAwesomeIcons.gear, 'Pengaturan'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scrim() => AnimatedBuilder(
        animation: _dcT,
        builder: (_, __) {
          final t = _dcT.value.clamp(0.0, 1.0).toDouble();
          if (t <= 0.001 && !_drawer) return const SizedBox.shrink();
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setDrawer(false),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5 * t + 0.01, sigmaY: 5 * t + 0.01),
                child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.533 * t)),
              ),
            ),
          );
        },
      );

  Widget _nav(AppView v, IconData icon, String label, {int badge = 0}) {
    final a = _view == v;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Sfx.click();
          _go(v);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: a
                ? const LinearGradient(colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)])
                : null,
            border: Border(left: BorderSide(color: a ? Colors.white : Colors.transparent, width: 3)),
          ),
          child: Row(children: [
            Icon(icon, size: 15, color: a ? Colors.white : C.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: a ? Colors.white : C.muted)),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(99)),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
          ]),
        ),
      ),
    );
  }
}


class _Hamburger extends StatefulWidget {
  const _Hamburger({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  State<_Hamburger> createState() => _HamburgerState();
}

/// .hb: 3 garis jadi X (0.35s cubic-bezier(.6,0,.2,1)), tekan mengecil .88 lalu memantul.
class _HamburgerState extends State<_Hamburger> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
        vsync: this,
        animationBehavior: AnimationBehavior.preserve,
    duration: const Duration(milliseconds: 350),
    value: widget.open ? 1 : 0,
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: const Cubic(0.6, 0, 0.2, 1));
  bool _down = false;

  @override
  void didUpdateWidget(covariant _Hamburger old) {
    super.didUpdateWidget(old);
    if (widget.open != old.open) {
      widget.open ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bar() => Container(
        width: 20,
        height: 2,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: Duration(milliseconds: _down ? 90 : 250),
        curve: _down ? Curves.easeOut : const Cubic(0.34, 1.7, 0.5, 1),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: C.glassBorder),
          ),
          child: AnimatedBuilder(
            animation: _t,
            builder: (_, __) {
              final t = _t.value;
              return SizedBox(
                width: 20,
                height: 16,
                child: Stack(children: [
                  Positioned(
                    top: 0,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(0.0, 7 * t)
                        ..rotateZ(0.785398 * t),
                      child: _bar(),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0).toDouble(),
                      child: Transform.scale(scaleX: (1 - t).clamp(0.0, 1.0).toDouble(), child: _bar()),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(0.0, -7 * t)
                        ..rotateZ(-0.785398 * t),
                      child: _bar(),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Titik status berdenyut (pul), digerakkan detak latar supaya tidak menambah frame ekstra.
class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  Widget _dot(double op, double sc) => Opacity(
        opacity: op,
        child: Transform.scale(
          scale: sc,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withAlpha(150), blurRadius: 8)],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!pulse) return _dot(1, 1);
    return ValueListenableBuilder<int>(
      valueListenable: Fx.tick,
      builder: (_, __, ___) {
        final t = (Fx.clock.elapsedMilliseconds % 1600) / 1600.0;
        final k = 1 - (2 * t - 1).abs();
        return _dot(1 - 0.45 * k, 1 + 0.18 * k);
      },
    );
  }
}
