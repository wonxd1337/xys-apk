import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/api.dart';
import '../core/fa.dart';
import '../core/format.dart';
import '../core/sfx.dart';
import '../core/theme.dart';
import '../models/item.dart';
import '../state/dash_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_switch.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_text.dart';
import '../widgets/page_title.dart';
import '../widgets/reveal.dart';
import '../widgets/toast.dart';
import 'webhook_view.dart' show mapsOf, truthy;

const _slots = 4; // slot hotbar

/// Showcase Item: item bermutasi yang dipegang (auto equip) bergantian agar dilihat pembeli.
class ShowcaseView extends StatefulWidget {
  const ShowcaseView({super.key, required this.active});
  final bool active;

  @override
  State<ShowcaseView> createState() => _ShowcaseViewState();
}

class _ShowcaseViewState extends State<ShowcaseView> {
  Map<String, dynamic>? _sh;
  String? _err;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _load();
      _sync();
    }
  }

  @override
  void didUpdateWidget(covariant ShowcaseView old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
    if (widget.active != old.active) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (widget.active) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!_busy) _load();
      });
    }
  }

  List<Item> get _sel => mapsOf(_sh?['selected']).map(Item.new).toList();
  List<Item> get _items => mapsOf(_sh?['items']).map(Item.new).toList();
  bool get _on => truthy(_sh?['enabled']);

  void _toast(String m, {IconData icon = FaS.circleCheck}) {
    if (mounted) showToast(context, m, icon: icon);
  }

  Future<void> _load() async {
    try {
      final d = await Api.call('showcase_get', username: dash.user);
      if (d['status'] != 'ok') throw ApiException('${d['message'] ?? 'error'}');
      if (!mounted) return;
      setState(() {
        _sh = d;
        _err = null;
      });
      dash.ensureIcons([..._sel.map((e) => e.iconId), ..._items.map((e) => e.iconId)]);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

  Future<void> _act(Map<String, dynamic> body) async {
    if (_busy) return;
    _busy = true;
    try {
      final r = await Api.call('showcase_save', body: {'username': dash.user, ...body});
      if (!mounted) return;
      if (r['status'] != 'ok') {
        _toast('${r['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.circleExclamation);
      } else {
        _toast('${r['message'] ?? 'OK'}');
      }
      await _load();
    } catch (e) {
      _toast('Gagal: $e', icon: FontAwesomeIcons.circleExclamation);
    } finally {
      _busy = false;
    }
  }

  Widget _head(IconData icon, String text, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 11),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          const Spacer(),
          if (trailing != null) trailing,
        ]),
      );

  BoxDecoration get _boxDeco => BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.glassBorder),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(14, 10, 14, 90 + bottom),
        children: [
          const PageTitle(FaS.star, 'Showcase Item'),
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('Auto Equip Mutated Items for Showcase to buyyer.',
                style: TextStyle(color: C.muted, fontSize: 12.8)),
          ),
          if (_sh == null && _err != null)
            EmptyState(FontAwesomeIcons.triangleExclamation, 'Gagal memuat Showcase: $_err')
          else if (_sh == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else ...[
            Reveal(child: _mainCard()),
            const SizedBox(height: 18),
            _head(
              FaS.eye,
              'Preview (${_sel.length})',
              trailing: _sel.isEmpty
                  ? null
                  : GlowButton(
                      kind: BtnKind.dark,
                      height: 34,
                      radius: 13,
                      icon: FaS.trashCan,
                      label: 'Delete',
                      onPressed: () => _act({'op': 'clear'}),
                    ),
            ),
            _preview(),
            const SizedBox(height: 22),
            _head(FaS.gem, 'Mutated Items'),
            _grid(screenH),
          ],
        ],
      ),
    );
  }

  Widget _mainCard() {
    final n = _sel.length;
    final on = _on;
    final chip = !on
        ? 'Nonaktif'
        : n == 0
            ? 'Belum ada item dipilih'
            : n > _slots
                ? '$n item, bergantian di hotbar ($_slots slot)'
                : '$n item dipegang bergantian';
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Auto Equip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            const SizedBox(height: 3),
            Text(chip, style: const TextStyle(color: C.muted, fontSize: 12.5)),
          ]),
        ),
        const SizedBox(width: 12),
        GlassSwitch(value: on, large: true, onChanged: (_) => _act({'op': 'enabled', 'value': on ? 0 : 1})),
      ]),
    );
  }

  Widget _preview() {
    final sel = _sel;
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(10),
      decoration: _boxDeco,
      child: sel.isEmpty
          ? const EmptyState(FaS.star, 'Belum ada item. Pilih item bermutasi di bawah.')
          : LayoutBuilder(
              builder: (_, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < sel.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _PreviewTile(
                          item: sel[i],
                          index: i,
                          iconUrl: dash.icons[sel[i].iconId],
                          onRemove: () {
                            Sfx.click();
                            _act({'op': 'remove', 'uuid': sel[i].uuid});
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _grid(double screenH) {
    final items = _items;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: math.min(screenH * 0.58, 520)),
      padding: const EdgeInsets.all(10),
      decoration: _boxDeco,
      child: items.isEmpty
          ? EmptyState(FaS.gem,
              _sel.isNotEmpty ? 'Semua item bermutasi sudah dipilih.' : 'Tidak ada item bermutasi di inventaris.')
          : SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final x in items)
                    _ListTile(
                      item: x,
                      inBooth: truthy(x.raw['in_booth']),
                      iconUrl: dash.icons[x.iconId],
                      onTap: () {
                        Sfx.click();
                        _act({'op': 'add', 'uuid': x.uuid});
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

// ---------- potongan teks ----------
List<Shadow> _ol([Color c = Colors.black]) => [
      Shadow(color: c, offset: const Offset(-1, 0)),
      Shadow(color: c, offset: const Offset(1, 0)),
      Shadow(color: c, offset: const Offset(0, -1)),
      Shadow(color: c, offset: const Offset(0, 1)),
    ];

/// Label mutasi: teks gradient + garis tepi hitam tipis (tanpa background).
class _MutLabel extends StatelessWidget {
  const _MutLabel(this.item, {this.size = 9.3, this.maxLines = 1});
  final Item item;
  final double size;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final ms = parseMutationColor(item.mutationColor);
    final t = item.mutName.toUpperCase();
    final base = TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 0.2, height: 1.1);
    return Stack(children: [
      Text(
        t,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: base.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xCC000000),
        ),
      ),
      ms.isNotEmpty
          ? GradientText(t,
              gradient: mutationGradient(ms), style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis)
          : Text(t,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(color: const Color(0xFFFFD27A))),
    ]);
  }
}

class _BareIcon extends StatelessWidget {
  const _BareIcon(this.url);
  final String? url;

  @override
  Widget build(BuildContext context) {
    const fb = Icon(FaS.gem, size: 20, color: C.muted);
    if (url == null) return const Center(child: fb);
    return Image.network(url!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: fb));
  }
}

class _GradBorder extends CustomPainter {
  _GradBorder(this.g, this.radius, this.width);
  final Gradient g;
  final double radius, width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(width / 2), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = g.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GradBorder o) => o.g != g || o.radius != radius || o.width != width;
}

/// Preview (.shv): tanpa background, hanya border gradient mengikuti warna mutasi.
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.item, required this.index, required this.iconUrl, required this.onRemove});
  final Item item;
  final int index;
  final String? iconUrl;
  final VoidCallback onRemove;

  String get _name {
    final sz = item.size == 'max' ? 'Maxton ' : (item.size == 'big' ? 'Big ' : '');
    return (item.isShiny ? 'Shiny ' : '') + sz + item.baseName;
  }

  @override
  Widget build(BuildContext context) {
    final rc = rarityColor(item.rarity);
    final ms = parseMutationColor(item.mutationColor);
    final grad = ms.isNotEmpty ? mutationGradient(ms) : LinearGradient(colors: [rc, rc]);
    final iconTop = item.mutOn ? 21.0 : 20.0;
    return GestureDetector(
      onTap: onRemove,
      child: CustomPaint(
        foregroundPainter: _GradBorder(grad, 15, 1.5),
        child: SizedBox(
          width: 78,
          height: 94,
          child: Stack(children: [
            Positioned(
              top: 6,
              left: 7,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${index + 1}', style: const TextStyle(color: Color(0x8CFFFFFF))),
                  if (item.hasWeight) TextSpan(text: '  ${fw(item.weight)}'),
                ]),
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, shadows: _ol(const Color(0xAA000000))),
              ),
            ),
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xA6000000)),
                child: const Icon(FontAwesomeIcons.xmark, size: 8),
              ),
            ),
            if (item.mutOn)
              Positioned(top: 20, left: 3, right: 3, child: Center(child: _MutLabel(item, size: 9.3))),
            Positioned(top: iconTop, left: 14, width: 50, height: 50, child: _BareIcon(iconUrl)),
            Positioned(
              top: iconTop + 39,
              left: 3,
              right: 3,
              child: Text(
                _name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.6,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  color: rc,
                  shadows: [..._ol(), const Shadow(color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 3)],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Item pilihan (.shl): kotak 76px, warna mengikuti rarity.
class _ListTile extends StatefulWidget {
  const _ListTile({required this.item, required this.inBooth, required this.iconUrl, required this.onTap});
  final Item item;
  final bool inBooth;
  final String? iconUrl;
  final VoidCallback onTap;

  @override
  State<_ListTile> createState() => _ListTileState();
}

class _ListTileState extends State<_ListTile> {
  bool _down = false;

  Widget _sz(String t, Color c) => Text(
        t.toUpperCase(),
        style: TextStyle(fontSize: 8.9, fontWeight: FontWeight.w900, height: 1.15, color: c, shadows: _ol(const Color(0xAA000000))),
      );

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final rc = rarityColor(it.rarity);
    final border = Color.lerp(rc, Colors.black, 0.35)!;
    final top = Color.lerp(const Color(0xFF0B0B0D), rc, 0.32)!;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 2),
              gradient: LinearGradient(
                begin: const Alignment(-0.6, -1),
                end: const Alignment(0.6, 1),
                colors: [top, const Color(0xFF0B0B0D)],
                stops: const [0, 0.85],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                if (it.mutOn)
                  Positioned(
                    left: 5,
                    top: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 40),
                      child: _MutLabel(it, size: 8.9, maxLines: 2),
                    ),
                  ),
                Positioned(
                  right: 5,
                  top: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.inBooth)
                        const Icon(FontAwesomeIcons.tag, size: 8, color: Color(0xFFFFD24A)),
                      if (it.isShiny) _sz('Shiny', const Color(0xFF8FF3FF)),
                      if (it.size == 'max')
                        _sz('Maxton', const Color(0xFFFFD24A))
                      else if (it.size == 'big')
                        _sz('Big', const Color(0xFFC4B0FF)),
                      if (it.hasWeight)
                        Text(fw(it.weight),
                            style: TextStyle(fontSize: 8.9, fontWeight: FontWeight.w800, height: 1.15, color: Colors.white, shadows: _ol(const Color(0xAA000000)))),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.06),
                    child: SizedBox(width: 45, height: 45, child: _BareIcon(widget.iconUrl)),
                  ),
                ),
                Positioned(
                  left: 3,
                  right: 3,
                  bottom: 4,
                  child: Text(
                    it.baseName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.3, fontWeight: FontWeight.w800, height: 1.1, color: Colors.white, shadows: _ol()),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
