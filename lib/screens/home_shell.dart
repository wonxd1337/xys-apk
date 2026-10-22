import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/api.dart';
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
import 'webhook_view.dart';

enum AppView { dash, queue, hist, wh, find, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  bool _drawer = false;
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

  void _go(AppView v) => setState(() {
        _view = v;
        _drawer = false;
      });

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
            setState(() {
              if (_drawer) {
                _drawer = false;
              } else {
                _view = AppView.dash;
              }
            });
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
                              active: _view == AppView.settings,
                              child: SettingsView(onSaved: () => _go(AppView.dash))),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_drawer)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _drawer = false),
                      child: BackdropFilter(
                        filter: _blur5,
                        child: const ColoredBox(color: Color(0x88000000)),
                      ),
                    ),
                  ),
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
              _Hamburger(open: _drawer, onTap: () => setState(() => _drawer = !_drawer)),
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
      child: IgnorePointer(
        ignoring: !_drawer,
        child: AnimatedSlide(
          offset: Offset(_drawer ? 0 : -1.2, 0),
          duration: const Duration(milliseconds: 550),
          curve: const Cubic(0.2, 0.9, 0.2, 1),
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
                    child: Text('Deoxys Umbreon',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  ),
                ]),
                const SizedBox(height: 22),
                _nav(AppView.dash, FontAwesomeIcons.gaugeHigh, 'Dashboard', i: 0),
                _nav(AppView.queue, FontAwesomeIcons.bagShopping, 'Antrian Jual',
                    badge: dash.queue.length, i: 1),
                _nav(AppView.hist, FontAwesomeIcons.clockRotateLeft, 'Riwayat Penjualan', i: 2),
                _nav(AppView.wh, FontAwesomeIcons.discord, 'Webhook', i: 3),
                _nav(AppView.find, FontAwesomeIcons.magnifyingGlass, 'Find Items', i: 4),
                const Spacer(),
                _nav(AppView.settings, FontAwesomeIcons.gear, 'Pengaturan', i: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(AppView v, IconData icon, String label, {int badge = 0, int i = 0}) {
    final a = _view == v;
    final ms = 320 + 70 * i;
    return AnimatedSlide(
      offset: Offset(_drawer ? 0 : -0.35, 0),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _drawer ? 1 : 0,
        duration: Duration(milliseconds: ms),
        child: Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _go(v),
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
    )));
  }
}

final _blur5 = ImageFilter.blur(sigmaX: 5, sigmaY: 5);

class _Hamburger extends StatelessWidget {
  const _Hamburger({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  Widget _bar() => Container(
        height: 2,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: C.glassBorder),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: open ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          builder: (_, t, __) => SizedBox(
            width: 20,
            height: 16,
            child: Stack(children: [
              Positioned(
                top: 7 * t,
                left: 0,
                right: 0,
                child: Transform.rotate(angle: 0.785398 * t, child: _bar()),
              ),
              Positioned(
                top: 7,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(scaleX: 1 - t, child: _bar()),
                ),
              ),
              Positioned(
                top: 14 - 7 * t,
                left: 0,
                right: 0,
                child: Transform.rotate(angle: -0.785398 * t, child: _bar()),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.pulse) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Opacity(
          opacity: 1 - 0.45 * _c.value,
          child: Transform.scale(
            scale: 1 + 0.18 * _c.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [BoxShadow(color: widget.color.withAlpha(150), blurRadius: 8)],
              ),
            ),
          ),
        ),
      );
}
