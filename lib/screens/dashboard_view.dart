import 'package:flutter/material.dart';
import '../core/fa.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/format.dart';
import '../core/sfx.dart';
import '../core/theme.dart';
import '../models/item.dart';
import '../state/dash_state.dart';
import '../widgets/confirm_box.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/glass_input.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_text.dart';
import '../widgets/item_card.dart';
import '../widgets/item_widgets.dart';
import '../widgets/oxz_loader.dart';
import '../widgets/reveal.dart';
import '../widgets/skip_dialog.dart';
import '../widgets/stat_card.dart';
import '../widgets/toast.dart';

enum DashTab { booth, inv }

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final st = dash;
  DashTab tab = DashTab.booth;
  bool selMode = false;
  final sel = <String>{};
  final _q = TextEditingController();
  final _slp = TextEditingController();
  final _ctl = <String, TextEditingController>{};
  String invCat = '*';
  bool _busy = false;
  DateTime _lastAuto = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    st.addListener(_onState);
    _q.addListener(() => setState(() {}));
    SharedPreferences.getInstance().then((p) {
      final c = p.getString('c');
      if (c != null && mounted) setState(() => invCat = c);
    });
  }

  @override
  void dispose() {
    st.removeListener(_onState);
    _q.dispose();
    _slp.dispose();
    super.dispose();
  }

  // ---------- data turunan ----------
  List<Item> _boothSorted() {
    final l = [...st.booth];
    l.sort((a, b) {
      final m = (b.mutOn ? 1 : 0) - (a.mutOn ? 1 : 0);
      return m != 0 ? m : b.price.compareTo(a.price);
    });
    return l;
  }

  List<Item> _visInv() {
    final q = _q.text.toLowerCase();
    return st.inv
        .where((x) =>
            (invCat == '*' || x.category == invCat) && x.nameText.toLowerCase().contains(q))
        .toList();
  }

  double? _selPrice() {
    for (final z in st.booth) {
      if (sel.contains(z.uuid)) return z.price;
    }
    return null;
  }

  TextEditingController _priceCtl(String uuid) =>
      _ctl.putIfAbsent(uuid, () => TextEditingController());

  void _onState() {
    if (!mounted) return;
    final ok = (tab == DashTab.booth ? st.booth : _visInv()).map((e) => e.uuid).toSet();
    sel.removeWhere((u) => !ok.contains(u));
    final alive = st.inv.map((e) => e.uuid).toSet();
    _ctl.removeWhere((k, _) => !alive.contains(k));
    setState(() {});
    _maybeAuto();
  }

  /// inventaris basi + bot online -> minta refresh otomatis (maks. 1x / 90 dtk)
  Future<void> _maybeAuto() async {
    if (tab != DashTab.inv) return;
    final old = st.invAge == null || st.invAge! > 300;
    if (old &&
        st.bot.status == 'online' &&
        DateTime.now().difference(_lastAuto).inSeconds > 90) {
      _lastAuto = DateTime.now();
      try {
        final r = await st.cmd({'type': 'refresh'});
        if (r['status'] == 'ok' && mounted) {
          showToast(context, 'Refreshing Inventory', icon: FontAwesomeIcons.rotate);
        }
      } catch (_) {}
    }
  }

  void _toast(String m, {IconData icon = FaS.circleCheck}) {
    if (mounted) showToast(context, m, icon: icon);
  }

  void _warn(String m) {
    HapticFeedback.mediumImpact();
    _toast(m, icon: FontAwesomeIcons.circleExclamation);
  }

  /// Kirim perintah ke bot. true kalau diterima.
  Future<bool> _send(Map<String, dynamic> body) async {
    try {
      final r = await st.cmd(body);
      if (r['status'] != 'ok') {
        _toast('${r['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.triangleExclamation);
        return false;
      }
      st.markSent(((r['done'] as List?) ?? []).map((e) => '$e'));
      _toast('${r['message'] ?? 'OK'}' +
          (st.bot.status == 'offline' ? ' (bot offline, dijalankan saat online)' : ''));
      st.load(force: true);
      return true;
    } catch (_) {
      _toast('Gagal terhubung ke server', icon: FontAwesomeIcons.triangleExclamation);
      return false;
    }
  }

  // ---------- aksi satu item ----------
  Future<void> _sell(Item it, {bool skip = false}) async {
    if (_busy) return;
    final pv = (double.tryParse(_priceCtl(it.uuid).text.trim()) ?? 0).round();
    if (pv <= 0) return _warn('Isi harga dulu');
    final body = <String, dynamic>{'type': 'sell', 'uuid': it.uuid, 'price': pv};

    _busy = true;
    bool ok;
    if (skip) {
      final r = await showGlassDialog<Map<String, dynamic>>(
        context,
        (_) => SkipDialog(item: it, price: pv, booth: st.booth, icons: st.icons),
      );
      ok = r != null;
      if (r != null) body.addAll(r);
    } else {
      ok = await confirmBox(
        context,
        title: 'Sell This Item?',
        icon: FontAwesomeIcons.bolt,
        okIcon: FontAwesomeIcons.bolt,
        okLabel: 'Ye',
        body: ItemSummary(
          item: it,
          iconUrl: st.icons[it.iconId],
          price: pv,
          note: st.full ? 'Ur Booth Curently Full, Moved To Queue Item' : null,
        ),
      );
    }
    _busy = false;
    if (ok) await _send(body);
  }

  Future<void> _editPrice(Item it) async {
    if (_busy) return;
    final ctl = TextEditingController(text: '${it.price.round()}');
    _busy = true;
    final ok = await confirmBox(
      context,
      title: 'Edit Price',
      icon: FontAwesomeIcons.pen,
      okIcon: FontAwesomeIcons.pen,
      okLabel: 'Save',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemSummary(item: it, iconUrl: st.icons[it.iconId]),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Current Price: ', style: TextStyle(color: C.muted, fontSize: 13.6)),
            PriceText(it.price),
          ]),
          const SizedBox(height: 12),
          GlassInput(controller: ctl, hint: 'Harga baru', number: true, autofocus: true),
          const SizedBox(height: 12),
          const Text('Item akan dipasang ulang dengan harga baru.',
              style: TextStyle(color: C.muted, fontSize: 13.6)),
        ],
      ),
    );
    _busy = false;
    if (!ok) return;
    final np = (double.tryParse(ctl.text.trim()) ?? 0).round();
    if (np <= 0) return _warn('Fill This!');
    if (np == it.price.round()) return _warn('Harga sama dengan harga sekarang');
    await _send({'type': 'edit_price', 'uuid': it.uuid, 'price': np});
  }

  Future<void> _unlist(Item it) async {
    if (_busy) return;
    _busy = true;
    final ok = await confirmBox(
      context,
      title: 'Unlist This Item?',
      icon: FontAwesomeIcons.storeSlash,
      danger: true,
      okLabel: 'Ye',
      body: ItemSummary(
        item: it,
        iconUrl: st.icons[it.iconId],
        price: it.price,
        note: 'Item akan diturunkan dari booth.',
      ),
    );
    _busy = false;
    if (ok) await _send({'type': 'unlist', 'uuid': it.uuid});
  }

  // ---------- mode Pilih ----------
  void _toggleSel() => setState(() {
        selMode = !selMode;
        sel.clear();
      });

  void _pick(Item z) {
    if (st.sent.contains(z.uuid)) return;
    final bo = tab == DashTab.booth;
    if (sel.contains(z.uuid)) {
      setState(() => sel.remove(z.uuid));
      return;
    }
    if (bo && sel.isNotEmpty && z.price != _selPrice()) {
      return _warn('Hanya bisa memilih item dengan harga yang sama');
    }
    setState(() => sel.add(z.uuid));
  }

  void _pickAll() {
    final bo = tab == DashTab.booth;
    final sp = _selPrice();
    final ids = (bo
            ? (sp == null ? <Item>[] : st.booth.where((z) => z.price == sp))
            : _visInv())
        .map((z) => z.uuid)
        .where((u) => !st.sent.contains(u))
        .toList();
    setState(() {
      if (ids.isNotEmpty && ids.every(sel.contains)) {
        sel.removeAll(ids);
      } else {
        sel.addAll(ids);
      }
    });
  }

  Future<void> _bulk(bool unlist) async {
    if (_busy || sel.isEmpty) return;
    final bo = tab == DashTab.booth;
    final L = (bo ? st.booth : st.inv).where((z) => sel.contains(z.uuid)).toList();
    if (L.isEmpty) return;

    var price = 0;
    if (!unlist) {
      price = (double.tryParse(_slp.text.trim()) ?? 0).round();
      if (price <= 0) return _warn('Isi harga dulu');
    }
    final type = unlist ? 'unlist' : (bo ? 'edit_price' : 'sell');
    final n = L.length, free = st.max - st.used;

    _busy = true;
    final bool ok;
    if (type == 'sell') {
      ok = await confirmBox(
        context,
        title: 'Jual $n item?',
        icon: FontAwesomeIcons.bolt,
        okIcon: FontAwesomeIcons.bolt,
        okLabel: 'Ya, Jual',
        body: ManySummary(
          items: L,
          price: price,
          note: free <= 0
              ? 'Booth penuh, semua item masuk antrian.'
              : (n > free
                  ? 'Slot booth tersisa $free: $free item langsung dipasang, sisanya masuk antrian.'
                  : null),
        ),
      );
    } else if (type == 'edit_price') {
      ok = await confirmBox(
        context,
        title: 'Edit harga $n item?',
        icon: FontAwesomeIcons.pen,
        okIcon: FontAwesomeIcons.pen,
        okLabel: 'Ya, Ubah',
        body: ManySummary(
          items: L,
          price: price,
          note:
              'Harga lama ${fmt(L.first.price)} → ${fmt(price)}. Item dipasang ulang dengan harga baru.',
        ),
      );
    } else {
      ok = await confirmBox(
        context,
        title: 'Unlist $n item?',
        icon: FaS.trashCan,
        okIcon: FaS.trashCan,
        okLabel: 'Ya, Unlist',
        danger: true,
        body: ManySummary(items: L, note: 'Item akan diturunkan dari booth.'),
      );
    }
    _busy = false;
    if (!ok) return;

    final done = await _send({
      'type': type,
      'uuids': L.map((z) => z.uuid).toList(),
      'price': price,
      'skip': 0,
    });
    if (done && mounted) {
      setState(() {
        selMode = false;
        sel.clear();
        _slp.clear();
      });
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final bo = tab == DashTab.booth;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (!st.loaded) {
      return st.error != null
          ? _errorBox()
          : const Center(child: OxzLoader());
    }

    final list = bo ? _boothSorted() : _visInv();
    final cats = <String, int>{};
    for (final x in st.inv) {
      cats[x.category] = (cats[x.category] ?? 0) + 1;
    }
    if (invCat != '*' && !cats.containsKey(invCat)) invCat = '*';

    return Stack(
      children: [
        RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => st.load(force: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Reveal(child: _title()),
                      if (st.error != null) _errorBanner(),
                      _banner(),
                      _stats(),
                      Reveal(index: 4, child: _toolbar()),
                      if (!bo && cats.isNotEmpty) _cats(cats),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverToBoxAdapter(
                  child: _empty(
                    bo ? FontAwesomeIcons.store : FontAwesomeIcons.boxOpen,
                    bo
                        ? 'Booth Empty. Sell items from inventory.'
                        : 'Tidak ada item. Inventaris kosong, atau semua sudah dipajang / antri.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _card(list[i], i),
                      childCount: list.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: (selMode ? 190 : 90) + bottomInset),
              ),
            ],
          ),
        ),
        if (selMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 14 + bottomInset,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 680,
                  minWidth: 0,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _selBar(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _errorBox() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _empty(FontAwesomeIcons.triangleExclamation,
              'Gagal membaca api.php: ${st.error}\nPeriksa URL server di menu Pengaturan.'),
        ),
      );

  Widget _errorBanner() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _bn(C.red, FontAwesomeIcons.plugCircleXmark,
            'Tidak bisa terhubung: ${st.error}. Mencoba lagi otomatis.'),
      );

  Widget _empty(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, size: 38, color: const Color(0x99FFFFFF)),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted, height: 1.4)),
          ],
        ),
      );

  Widget _title() => Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
        child: Row(
          children: [
            const Icon(FontAwesomeIcons.gaugeHigh, size: 16),
            const SizedBox(width: 9),
            const GradientText('Deoxys',
                gradient: titleGradient,
                style: TextStyle(fontSize: 17.6, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _bn(Color c, IconData icon, String text) => GlassCard(
        radius: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: c, width: 3))),
          child: Row(
            children: [
              Icon(icon, size: 15, color: c),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.35))),
            ],
          ),
        ),
      );

  Widget _banner() {
    final b = st.bot;
    Widget? w;
    if (b.status == 'hopping') {
      w = _bn(C.amber, FontAwesomeIcons.shuffle,
          'Bot sedang pindah server. Data akan tersinkron otomatis begitu bot masuk lagi.');
    } else if (b.status == 'offline' && st.connected) {
      w = _bn(
          C.red,
          FontAwesomeIcons.plugCircleXmark,
          'Bot offline${b.age != null ? ' (terakhir terlihat ${ago(b.age)} lalu)' : ''}. Perintah dari dashboard akan dijalankan saat bot kembali online.');
    }
    return w == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(bottom: 16), child: w);
  }

  Widget _stats() {
    final slotFull = st.used >= st.max;
    final c = [
      StatCard(
        icon: FontAwesomeIcons.coins,
        label: 'Current Token',
        value: CountUp(st.tokens, style: statValueStyle),
      ),
      StatCard(
        icon: FontAwesomeIcons.store,
        label: 'Booth Slot',
        bar: st.max > 0 ? st.used / st.max : 0,
        value: Text(
          '${st.booth.length} / ${st.max}${st.reserved > 0 ? ' (+${st.reserved} dikunci)' : ''}',
          style: statValueStyle.copyWith(color: slotFull ? const Color(0xFFFF6B6B) : Colors.white),
        ),
      ),
      StatCard(
        icon: FontAwesomeIcons.stopwatch,
        label: st.bot.stock == 0 ? 'Booth kosong (tdk hop)' : 'Hop Server',
        value: const HopTimerText(),
      ),
      StatCard(
        icon: FontAwesomeIcons.bagShopping,
        label: 'Sold Item',
        value: CountUp(st.soldCount, style: statValueStyle),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: Reveal(index: 1, child: c[0])),
          const SizedBox(width: 8),
          Expanded(child: Reveal(index: 2, child: c[1])),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Reveal(index: 3, child: c[2])),
          const SizedBox(width: 8),
          Expanded(child: Reveal(index: 4, child: c[3])),
        ]),
      ]),
    );
  }

  Widget _tabBtn(DashTab t, IconData icon, String label, int count) {
    final a = tab == t;
    return GestureDetector(
      onTap: () {
        if (tab == t) return;
        Sfx.click();
        setState(() {
          tab = t;
          sel.clear();
        });
        _maybeAuto();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: a ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: a ? const [BoxShadow(color: Color(0x55FFFFFF), blurRadius: 22)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: a ? Colors.black : C.muted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.4,
                    color: a ? Colors.black : C.muted)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: a ? Colors.black : C.muted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    final inv = tab == DashTab.inv;
    final old = st.invAge == null || st.invAge! > 300;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // baris 1: tab Booth/Inventory + tombol Pilih (btn d, ikon regular)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GlassCard(
                radius: 19,
                padding: const EdgeInsets.all(5),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _tabBtn(DashTab.booth, FontAwesomeIcons.store, 'Booth', st.booth.length),
                  const SizedBox(width: 4),
                  _tabBtn(DashTab.inv, FontAwesomeIcons.boxOpen, 'Inventory', st.inv.length),
                ]),
              ),
              GlowButton(
                kind: BtnKind.dark,
                height: 40,
                icon: selMode ? FontAwesomeIcons.xmark : FontAwesomeIcons.squareCheck,
                label: selMode ? 'Selesai' : 'Pilih',
                onPressed: _toggleSel,
              ),
            ],
          ),
          if (inv) ...[
            const SizedBox(height: 10),
            // baris 2: pencarian (melebar) + Refresh
            Row(children: [
              Expanded(
                child: GlassInput(
                  controller: _q,
                  hint: 'Search item...',
                  prefix: const Icon(FontAwesomeIcons.magnifyingGlass, size: 14, color: C.muted),
                ),
              ),
              const SizedBox(width: 10),
              GlowButton(
                height: 40,
                icon: FontAwesomeIcons.rotate,
                label: 'Refresh',
                onPressed: () async {
                  try {
                    final r = await st.cmd({'type': 'refresh'});
                    if (r['status'] == 'ok') {
                      _toast('Refreshing Inventory', icon: FontAwesomeIcons.rotate);
                    } else {
                      _toast('${r['message'] ?? 'Gagal'}',
                          icon: FontAwesomeIcons.triangleExclamation);
                    }
                  } catch (_) {
                    _toast('Gagal terhubung ke server',
                        icon: FontAwesomeIcons.triangleExclamation);
                  }
                },
              ),
            ]),
            const SizedBox(height: 10),
            // baris 3: umur sinkron inventaris (.fr)
            Text(
              'Inventaris: ${st.invAge == null ? 'belum disinkron' : '${ago(st.invAge)} lalu'}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: old ? C.amber : C.muted),
            ),
          ],
        ],
      ),
    );
  }

  IconData _catIcon(String c) {
    final k = c.toLowerCase();
    if (RegExp(r'fish').hasMatch(k)) return FontAwesomeIcons.fish;
    if (RegExp(r'bait|worm').hasMatch(k)) return FontAwesomeIcons.worm;
    if (RegExp(r'potion|flask').hasMatch(k)) return FontAwesomeIcons.flask;
    if (RegExp(r'crate|chest|box').hasMatch(k)) return FontAwesomeIcons.boxArchive;
    return FontAwesomeIcons.box;
  }

  String _catLbl(String c) => c
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[_-]+'), ' ');

  Widget _cats(Map<String, int> cats) {
    final keys = cats.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final all = <List<dynamic>>[
      ['*', st.inv.length, 'Semua', FontAwesomeIcons.layerGroup],
      ...keys.map((k) => [k, cats[k]!, _catLbl(k), _catIcon(k)]),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final k = all[i];
            final a = k[0] == invCat;
            return GestureDetector(
              onTap: () async {
                setState(() => invCat = k[0] as String);
                (await SharedPreferences.getInstance()).setString('c', invCat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: a ? Colors.white : const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: a ? Colors.white : C.glassBorder),
                  boxShadow: a ? const [BoxShadow(color: Color(0x44FFFFFF), blurRadius: 18)] : null,
                ),
                child: Row(children: [
                  Icon(k[3] as IconData, size: 12, color: a ? Colors.black : C.muted),
                  const SizedBox(width: 8),
                  Text(k[2] as String,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: a ? Colors.black : C.muted)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('${k[1]}',
                        style: TextStyle(fontSize: 11, color: a ? Colors.black : C.muted)),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _card(Item it, int idx) {
    final bo = tab == DashTab.booth;
    final selected = sel.contains(it.uuid);
    final sp = _selPrice();
    final dimmed = selMode && bo && sel.isNotEmpty && !selected && it.price != sp;
    return Padding(
      key: ValueKey('${tab.name}-${it.uuid}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: ItemCard(
        index: idx,
        item: it,
        isBooth: bo,
        full: st.full,
        sent: st.sent.contains(it.uuid),
        selMode: selMode,
        selected: selected,
        dimmed: dimmed,
        iconUrl: st.icons[it.iconId],
        priceCtl: bo ? null : _priceCtl(it.uuid),
        onTapSelect: () => _pick(it),
        onSell: () => _sell(it),
        onSkip: () => _sell(it, skip: true),
        onEdit: () => _editPrice(it),
        onUnlist: () => _unlist(it),
      ),
    );
  }

  Widget _selBar() {
    final bo = tab == DashTab.booth;
    final n = sel.length;
    final sp = _selPrice();
    final full = st.full;
    final Widget info = n > 0
        ? Text.rich(TextSpan(children: [
            TextSpan(text: '$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const TextSpan(text: ' dipilih'),
            if (bo && sp != null) ...[
              const TextSpan(text: '  ·  '),
              TextSpan(text: fmt(sp), style: const TextStyle(color: Color(0xFFFFD24A), fontWeight: FontWeight.w800)),
              const TextSpan(text: ' coins'),
            ],
          ]))
        : Text(bo ? 'Pilih item (hanya harga yang sama)' : 'Ketuk item untuk memilih');
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: C.muted, fontSize: 13.6),
                child: info,
              ),
            ),
            GlowButton(
              kind: BtnKind.dark,
              height: 40,
              icon: FontAwesomeIcons.listCheck,
              label: 'Semua',
              onPressed: (bo && n == 0) ? null : _pickAll,
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: GlassInput(
                controller: _slp,
                hint: bo ? 'Harga baru' : 'Harga jual',
                number: true,
                onSubmitted: (_) => _bulk(false),
              ),
            ),
            const SizedBox(width: 8),
            GlowButton(
              height: 42,
              icon: bo
                  ? FontAwesomeIcons.pen
                  : (full ? FontAwesomeIcons.hourglassHalf : FontAwesomeIcons.bolt),
              label: bo ? 'Edit Harga' : (full ? 'Antre' : 'Jual'),
              onPressed: n == 0 ? null : () => _bulk(false),
            ),
            if (bo) ...[
              const SizedBox(width: 8),
              GlowButton(
                kind: BtnKind.trash,
                height: 42,
                width: 52,
                padding: EdgeInsets.zero,
                icon: FaS.trashCan,
                onPressed: n == 0 ? null : () => _bulk(true),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

/// Hitung mundur hop server (mm:ss), dihitung lokal dari timer terakhir bot.
class HopTimerText extends StatefulWidget {
  const HopTimerText({super.key});

  @override
  State<HopTimerText> createState() => _HopTimerTextState();
}

class _HopTimerTextState extends State<HopTimerText> {
  late final _t = Stream.periodic(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _t,
      builder: (_, __) {
        final s = dash;
        String txt = '--:--';
        if (s.bot.status == 'online' && s.botTimer != null) {
          final r = (s.botTimer! - DateTime.now().difference(s.botTimerAt).inSeconds)
              .round()
              .clamp(0, 999999)
              .toInt();
          txt = '${(r ~/ 60).toString().padLeft(2, '0')}:${(r % 60).toString().padLeft(2, '0')}';
        }
        return Text(txt, style: statValueStyle);
      },
    );
  }
}
