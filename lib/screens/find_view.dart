import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/item.dart';
import '../state/dash_state.dart';
import '../widgets/confirm_box.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dropdown.dart';
import '../widgets/glass_input.dart';
import '../widgets/glass_switch.dart';
import '../widgets/glow_button.dart';
import '../widgets/item_widgets.dart';
import '../widgets/page_title.dart';
import '../widgets/pill.dart';
import '../widgets/reveal.dart';
import '../widgets/toast.dart';
import 'webhook_view.dart' show mapsOf, truthy;

const kFindSize = <DropOpt>[
  DropOpt('', 'Semua ukuran'),
  DropOpt('Big', 'Big ke atas'),
  DropOpt('Max', 'Maxton saja'),
];

String _clean(String s) =>
    s.replaceAll(RegExp(r'\bshiny\b', caseSensitive: false), '').replaceAll(RegExp(r'\s+'), ' ').trim();

String _digits(String? s) => RegExp(r'\d+').firstMatch(s ?? '')?.group(0) ?? '';

List<String> _strs(dynamic v) => v is List ? v.map((e) => '$e').toList() : <String>[];

/// Find Items: aturan pencarian item/mutasi + temuan terbaru dari bot.
class FindView extends StatefulWidget {
  const FindView({super.key, required this.active, required this.onGoWebhook});
  final bool active;
  final VoidCallback onGoWebhook;

  @override
  State<FindView> createState() => _FindViewState();
}

class _FindViewState extends State<FindView> {
  Map<String, dynamic>? _fd;
  String? _err;
  Timer? _timer;
  bool _form = false;
  bool _saving = false;
  bool _busy = false;
  int _ed = 0;
  List<String> _selItems = [], _selMuts = [];
  String _size = '';
  bool _ren = true;
  final _mp = TextEditingController();
  final _wn = TextEditingController();
  final _wx = TextEditingController();
  Map<String, String> _fdi = {}; // nama item (lowercase) -> id ikon

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _load();
      _syncTimer();
    }
  }

  @override
  void didUpdateWidget(covariant FindView old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
    if (widget.active != old.active) _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mp.dispose();
    _wn.dispose();
    _wx.dispose();
    super.dispose();
  }

  /// temuan & status disegarkan tiap 15 dtk selama halaman terbuka (form tidak diganggu)
  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.active) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (!_form) _load();
      });
    }
  }

  void _toast(String m, {IconData icon = FontAwesomeIcons.circleCheck}) {
    if (mounted) showToast(context, m, icon: icon);
  }

  Future<void> _load() async {
    try {
      final d = await Api.call('find_get', username: dash.user);
      if (d['status'] != 'ok') throw ApiException('${d['message'] ?? 'error'}');
      final fdi = <String, String>{};
      for (final x in mapsOf((d['catalog'] as Map?)?['items'])) {
        final k = strOf(x['name']).toLowerCase();
        final ic = _digits(strOf(x['icon']));
        if (ic.isNotEmpty && !fdi.containsKey(k)) fdi[k] = ic;
      }
      if (!mounted) return;
      setState(() {
        _fd = d;
        _fdi = fdi;
        _err = null;
      });
      dash.ensureIcons([
        ...mapsOf(d['rules']).expand((r) => _strs(r['items']).take(3)).map(_iconOfName),
        ...mapsOf(d['hits']).map((h) => Item(h).iconId.isNotEmpty
            ? Item(h).iconId
            : _iconOfName(strOf(h['base_name']).isEmpty ? strOf(h['item_name']) : strOf(h['base_name']))),
      ]);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

  Future<Map<String, dynamic>?> _post(String action, Map<String, dynamic> body) async {
    try {
      return await Api.call(action, body: body);
    } catch (e) {
      _toast('$e', icon: FontAwesomeIcons.triangleExclamation);
      return null;
    }
  }

  // ---------- data turunan ----------
  Map<String, dynamic> get _cfg => Map<String, dynamic>.from((_fd?['cfg'] as Map?) ?? {});
  List<Map<String, dynamic>> get _hooks => mapsOf(_fd?['hooks']);
  List<Map<String, dynamic>> get _rules => mapsOf(_fd?['rules']);
  List<Map<String, dynamic>> get _hits => mapsOf(_fd?['hits']);
  List<Map<String, dynamic>> get _catItems => mapsOf((_fd?['catalog'] as Map?)?['items']);
  List<Map<String, dynamic>> get _catMuts => mapsOf((_fd?['catalog'] as Map?)?['mutations']);

  String _iconOfName(String n) {
    final k = n.toLowerCase();
    return _fdi[k] ?? dash.nameIcons[k] ?? '';
  }

  String? _iconUrl(String name) {
    final id = _iconOfName(name);
    return id.isEmpty ? null : dash.icons[id];
  }

  /// warna mutasi: dari item di dashboard dulu (sama persis), baru katalog
  String _mutColor(String n) {
    final k = _clean(n).toLowerCase();
    if (k.isEmpty) return '';
    for (final x in [...dash.inv, ...dash.booth]) {
      if (x.mutationColor.isNotEmpty && x.mutName.toLowerCase() == k) return x.mutationColor;
    }
    for (final m in dash.sales) {
      final x = Item(m);
      if (x.mutationColor.isNotEmpty && x.mutName.toLowerCase() == k) return x.mutationColor;
    }
    for (final m in _catMuts) {
      if (_clean(strOf(m['name'])).toLowerCase() == k) return catalogColorToMut(strOf(m['color']));
    }
    return '';
  }

  String _rar(String base) {
    final k = base.toLowerCase();
    for (final x in [...dash.inv, ...dash.booth]) {
      if (strOf(x.raw['rarity']).isNotEmpty && x.baseName.toLowerCase() == k) return x.rarity;
    }
    for (final c in _catItems) {
      if (strOf(c['rarity']).isNotEmpty && strOf(c['name']).toLowerCase() == k) {
        return strOf(c['rarity']);
      }
    }
    return '';
  }

  Item _hitItem(Map<String, dynamic> h) {
    final o = Map<String, dynamic>.from(h);
    if (strOf(o['base_name']).isEmpty) o['base_name'] = strOf(h['item_name']);
    o['name'] = strOf(h['item_name']);
    o['mutation_color'] = _mutColor(_clean(strOf(o['mutation'])));
    final base = Item(o).baseName;
    if (strOf(o['icon']).isEmpty) o['icon'] = _iconOfName(base);
    if (strOf(o['rarity']).isEmpty) o['rarity'] = _rar(base);
    return Item(o);
  }

  // ---------- aksi ----------
  Future<void> _master() async {
    final c = _cfg;
    final want = truthy(c['enabled']) ? 0 : 1;
    if (want == 1 && !truthy(c['has_hook'])) {
      _toast('Pilih webhook Find Items dulu', icon: FontAwesomeIcons.circleExclamation);
      return;
    }
    final r = await _post('find_cfg_save', {'enabled': want});
    if (r == null) return;
    if (r['status'] != 'ok') {
      _toast('${r['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.triangleExclamation);
    } else {
      _toast(want == 1 ? 'Find Items ON' : 'Find Items OFF');
    }
    _load();
  }

  Future<void> _pickHook(String v) async {
    final id = int.tryParse(v) ?? 0;
    final r = await _post('find_cfg_save', {'webhook_id': id});
    if (r == null) return;
    if (r['status'] != 'ok') {
      _toast('${r['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.triangleExclamation);
    } else {
      _toast(id > 0 ? 'Webhook dipilih' : 'Webhook dilepas');
    }
    _load();
  }

  Future<void> _test() async {
    if (!truthy(_cfg['has_hook'])) {
      _toast('Pilih webhook Find Items dulu', icon: FontAwesomeIcons.circleExclamation);
      return;
    }
    _toast('Mengirim tes...', icon: FontAwesomeIcons.paperPlane);
    final r = await _post('find_test', {});
    if (r == null) return;
    _toast('${r['message'] ?? ''}',
        icon: r['status'] == 'ok'
            ? FontAwesomeIcons.circleCheck
            : FontAwesomeIcons.triangleExclamation);
    _load();
  }

  void _open(Map<String, dynamic>? r) {
    setState(() {
      _form = true;
      _ed = r == null ? 0 : numOf(r['id']).toInt();
      _selItems = r == null ? [] : _strs(r['items']);
      _selMuts = r == null ? [] : _strs(r['mutations']);
      _size = r == null ? '' : strOf(r['size']);
      final mp = r == null ? 0 : numOf(r['max_price']);
      final wn = r == null ? 0 : numOf(r['min_weight']);
      final wx = r == null ? 0 : numOf(r['max_weight']);
      _mp.text = mp > 0 ? '${mp.round()}' : '';
      _wn.text = wn > 0 ? '$wn' : '';
      _wx.text = wx > 0 ? '$wx' : '';
      _ren = r == null ? true : numOf(r['enabled']) != 0;
    });
    _syncTimer();
  }

  void _closeForm() {
    setState(() => _form = false);
    _syncTimer();
  }

  Future<void> _saveRule() async {
    if (_selItems.isEmpty && _selMuts.isEmpty) {
      _toast('Pilih minimal satu item atau mutasi', icon: FontAwesomeIcons.circleExclamation);
      return;
    }
    final body = <String, dynamic>{
      'id': _ed,
      'items': _selItems,
      'mutations': _selMuts,
      'size': _size,
      'max_price': double.tryParse(_mp.text.trim()) ?? 0,
      'min_weight': double.tryParse(_wn.text.trim()) ?? 0,
      'max_weight': double.tryParse(_wx.text.trim()) ?? 0,
      'enabled': _ren ? 1 : 0,
    };
    setState(() => _saving = true);
    final r = await _post('find_rule_save', body);
    if (mounted) setState(() => _saving = false);
    if (r == null) return;
    if (r['status'] != 'ok') {
      _toast('${r['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.triangleExclamation);
      return;
    }
    _closeForm();
    _toast('${r['message'] ?? 'Tersimpan'}');
    _load();
  }

  Future<void> _toggleRule(Map<String, dynamic> r) async {
    final on = numOf(r['enabled']) != 0;
    final x = await _post('find_rule_save', {'id': numOf(r['id']).toInt(), 'enabled': on ? 0 : 1});
    if (x == null) return;
    if (x['status'] != 'ok') {
      _toast('${x['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.triangleExclamation);
    } else {
      _toast(on ? 'Aturan dinonaktifkan' : 'Aturan diaktifkan');
    }
    _load();
  }

  Future<void> _deleteRule(Map<String, dynamic> r) async {
    if (_busy) return;
    _busy = true;
    final its = _strs(r['items']), ms = _strs(r['mutations']);
    final ok = await confirmBox(
      context,
      title: 'Hapus aturan?',
      icon: FontAwesomeIcons.trashCan,
      danger: true,
      okIcon: FontAwesomeIcons.trashCan,
      okLabel: 'Ya, Hapus',
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0x59000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(its.take(2).join(', ').isEmpty ? 'Semua item' : its.take(2).join(', '),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(ms.take(2).join(', ').isEmpty ? 'Semua mutasi' : ms.take(2).join(', '),
              style: const TextStyle(color: C.muted, fontSize: 12.5)),
        ]),
      ),
    );
    _busy = false;
    if (!ok) return;
    final x = await _post('find_rule_delete', {'id': numOf(r['id']).toInt()});
    if (x == null) return;
    _toast('${x['message'] ?? 'Dihapus'}', icon: FontAwesomeIcons.trashCan);
    _load();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(14, 10, 14, 90 + bottom),
        children: [
          const PageTitle(FontAwesomeIcons.magnifyingGlass, 'Find Items'),
          const SizedBox(height: 14),
          if (_fd == null && _err != null)
            EmptyState(FontAwesomeIcons.triangleExclamation, 'Gagal memuat Find Items: $_err')
          else if (_fd == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else ...[
            Reveal(child: _mainCard()),
            const SizedBox(height: 18),
            _sec(FontAwesomeIcons.filter, 'Aturan',
                trailing: _form
                    ? null
                    : GlowButton(
                        icon: FontAwesomeIcons.plus,
                        label: 'Tambah',
                        height: 40,
                        onPressed: () => _open(null),
                      )),
            const SizedBox(height: 12),
            if (_form)
              _ruleForm()
            else if (_rules.isEmpty)
              const EmptyState(FontAwesomeIcons.magnifyingGlass, 'Belum ada aturan')
            else
              for (var i = 0; i < _rules.length; i++) _ruleCard(_rules[i], i),
            const SizedBox(height: 10),
            _sec(FontAwesomeIcons.bell, 'Temuan terbaru'),
            const SizedBox(height: 12),
            if (_hits.isEmpty)
              const EmptyState(FontAwesomeIcons.bellSlash, 'Belum ada temuan')
            else
              for (var i = 0; i < _hits.length; i++) _hitCard(_hits[i], i),
          ],
        ],
      ),
    );
  }

  Widget _sec(IconData icon, String t, {Widget? trailing}) => Row(children: [
        Icon(icon, size: 14, color: C.muted),
        const SizedBox(width: 9),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const Spacer(),
        if (trailing != null) trailing,
      ]);

  Widget _chip(IconData icon, String text, bool bad, bool go) {
    final c = bad ? C.red : C.green;
    return GestureDetector(
      onTap: go ? widget.onGoWebhook : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withAlpha(0x22),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: c.withAlpha(0x66)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          if (go) ...[
            const SizedBox(width: 6),
            Icon(FontAwesomeIcons.chevronRight, size: 9, color: c),
          ],
        ]),
      ),
    );
  }

  Widget _mainCard() {
    final c = _cfg, hk = _hooks;
    final on = truthy(c['enabled']);
    final hasHook = truthy(c['has_hook']);
    final h = c['hook'] is Map ? Map<String, dynamic>.from(c['hook'] as Map) : null;
    final ls = h?['last_status'];
    final fail = h != null && ls != null && !(numOf(ls) >= 200 && numOf(ls) < 300);
    final go = hk.isEmpty || fail;

    Widget chip;
    if (hk.isEmpty) {
      chip = _chip(FontAwesomeIcons.triangleExclamation, 'Buat webhook Find Items', true, true);
    } else if (!hasHook) {
      chip = _chip(FontAwesomeIcons.triangleExclamation, 'Pilih webhook', true, false);
    } else if (fail) {
      chip = _chip(FontAwesomeIcons.circleExclamation,
          'Gagal${numOf(ls) > 0 ? ' (HTTP ${numOf(ls).toInt()})' : ''}', true, go);
    } else if (ls != null) {
      chip = _chip(
          FontAwesomeIcons.circleCheck,
          'Terkirim ${ago(h?['last_ago'] == null ? null : numOf(h!['last_ago']).toInt())} lalu',
          false,
          false);
    } else {
      chip = _chip(FontAwesomeIcons.circleCheck, 'Webhook siap', false, false);
    }

    final opts = <DropOpt>[
      DropOpt('0', hk.isEmpty ? 'Belum ada webhook' : 'Pilih webhook'),
      ...hk.map((w) => DropOpt('${numOf(w['id']).toInt()}',
          strOf(w['name']) + (numOf(w['enabled']) != 0 ? '' : ' (nonaktif)'))),
    ];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: on ? 1 : 0.72,
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(14),
        child: Column(
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
                    colors: [Colors.white, Color(0xFF8A8A8A)],
                  ),
                  boxShadow: on
                      ? const [BoxShadow(color: Color(0x55FFFFFF), blurRadius: 22)]
                      : null,
                ),
                child: const Icon(FontAwesomeIcons.magnifyingGlass, size: 17, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pencarian',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 5),
                  Align(alignment: Alignment.centerLeft, child: chip),
                ]),
              ),
              GlassSwitch(value: on, large: true, onChanged: (_) => _master()),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: GlassDropdown(
                  icon: FontAwesomeIcons.discord,
                  value: hasHook ? '${numOf(c['webhook_id']).toInt()}' : '0',
                  options: opts,
                  onChanged: _pickHook,
                ),
              ),
              const SizedBox(width: 8),
              GlowButton(
                kind: BtnKind.dark,
                icon: FontAwesomeIcons.paperPlane,
                height: 46,
                width: 48,
                radius: 14,
                padding: EdgeInsets.zero,
                onPressed: _test,
              ),
              const SizedBox(width: 8),
              GlowButton(
                kind: BtnKind.dark,
                icon: FontAwesomeIcons.gear,
                height: 46,
                width: 48,
                radius: 14,
                padding: EdgeInsets.zero,
                onPressed: widget.onGoWebhook,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _ruleCard(Map<String, dynamic> r, int i) {
    final its = _strs(r['items']), ms = _strs(r['mutations']);
    final on = numOf(r['enabled']) != 0;
    final wn = numOf(r['min_weight']), wx = numOf(r['max_weight']);
    final mpr = numOf(r['max_price']);
    final size = strOf(r['size']);
    final hits = numOf(r['hits']).toInt();

    final ics = <Widget>[
      if (its.isEmpty)
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x99000000),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: const Icon(FontAwesomeIcons.layerGroup, size: 14, color: C.muted),
        )
      else ...[
        for (final n in its.take(3)) ItemIcon(url: _iconUrl(n), size: 36),
        if (its.length > 3)
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x99000000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Text('+${its.length - 3}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
      ],
    ];
    final ttl = its.isEmpty
        ? 'Semua item'
        : its.take(2).join(', ') + (its.length > 2 ? ' +${its.length - 2}' : '');

    final spec = <Widget>[
      if (size == 'Max')
        const MaxLabel(compact: true)
      else if (size == 'Big')
        const Pill(FontAwesomeIcons.rulerCombined, 'Big+'),
      if (wn > 0 && wx > 0)
        Pill(FontAwesomeIcons.weightHanging, '${fw(wn)} – ${fw(wx)}')
      else if (wn > 0)
        Pill(FontAwesomeIcons.weightHanging, '≥ ${fw(wn)}')
      else if (wx > 0)
        Pill(FontAwesomeIcons.weightHanging, '≤ ${fw(wx)}'),
      if (mpr > 0) Pill(FontAwesomeIcons.coins, '≤ ${fmt(mpr)}', gold: true),
    ];
    if (spec.isEmpty) spec.add(const Pill(FontAwesomeIcons.infinity, 'Berat & harga bebas'));
    if (hits > 0) spec.add(Pill(FontAwesomeIcons.bell, fmt(hits)));

    return Reveal(
      index: i,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: on ? 1 : 0.55,
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Wrap(spacing: 6, children: ics),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(ttl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  GlassSwitch(value: on, onChanged: (_) => _toggleRule(r)),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: ms.isEmpty
                      ? [const Pill(FontAwesomeIcons.dna, 'Semua mutasi')]
                      : ms.map((n) => MutTag(name: n, colorStr: _mutColor(n), fontSize: 11.5)).toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: spec,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: GlowButton(
                      kind: BtnKind.dark,
                      height: 40,
                      radius: 13,
                      expand: true,
                      icon: FontAwesomeIcons.pen,
                      label: 'Edit',
                      onPressed: () => _open(r),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlowButton(
                    kind: BtnKind.trash,
                    height: 40,
                    width: 52,
                    radius: 13,
                    padding: EdgeInsets.zero,
                    icon: FontAwesomeIcons.trashCan,
                    onPressed: () => _deleteRule(r),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hitCard(Map<String, dynamic> h, int i) {
    final it = _hitItem(h);
    final a = h['ago'];
    return Reveal(
      index: i,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemIcon(url: dash.icons[it.iconId]),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: ItemName(it)),
                      const SizedBox(width: 8),
                      PriceText(it.price),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      if (it.size == 'big') const Pill(FontAwesomeIcons.rulerCombined, 'Big'),
                      Pill(FontAwesomeIcons.user,
                          strOf(h['seller']).isEmpty ? '-' : strOf(h['seller'])),
                      if (a != null) Pill(FontAwesomeIcons.clock, ago(numOf(a).toInt())),
                    ]),
                    ItemFooter(it),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(IconData icon, String t, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(icon, size: 12, color: C.muted),
              const SizedBox(width: 8),
              Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ]),
          ),
          child,
        ]),
      );

  Widget _ruleForm() {
    return Reveal(
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(FontAwesomeIcons.filter, size: 15),
              const SizedBox(width: 10),
              Text(_ed == 0 ? 'Tambah Aturan' : 'Edit Aturan',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
            ]),
            const SizedBox(height: 18),
            _step(
              FontAwesomeIcons.gem,
              'Item',
              _TagPicker(
                selected: _selItems,
                hint: 'Semua item',
                source: _catItems
                    .map((x) => _PickOpt(strOf(x['name']),
                        sub: strOf(x['category']), icon: _digits(strOf(x['icon']))))
                    .toList(),
                iconUrlOf: (n) => _iconUrl(n),
                colorOf: (_) => '',
                isItem: true,
                onChanged: (l) => setState(() => _selItems = l),
              ),
            ),
            _step(
              FontAwesomeIcons.dna,
              'Mutasi',
              _TagPicker(
                selected: _selMuts,
                hint: 'Semua mutasi',
                source: _catMuts
                    .map((x) => _PickOpt(strOf(x['name']), color: strOf(x['color'])))
                    .toList(),
                iconUrlOf: (_) => null,
                colorOf: _mutColor,
                isItem: false,
                onChanged: (l) => setState(() => _selMuts = l),
              ),
            ),
            _step(
              FontAwesomeIcons.rulerCombined,
              'Ukuran',
              GlassDropdown(value: _size, options: kFindSize, onChanged: (v) => setState(() => _size = v)),
            ),
            _step(
              FontAwesomeIcons.weightHanging,
              'Berat (kg)',
              Row(children: [
                Expanded(child: GlassInput(controller: _wn, decimal: true, hint: 'Min')),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(FontAwesomeIcons.minus, size: 11, color: C.muted),
                ),
                Expanded(child: GlassInput(controller: _wx, decimal: true, hint: 'Max')),
              ]),
            ),
            _step(
              FontAwesomeIcons.coins,
              'Harga maksimum',
              GlassInput(controller: _mp, number: true, hint: 'Bebas'),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                const Expanded(child: Text('Aktif', style: TextStyle(fontWeight: FontWeight.w600))),
                GlassSwitch(value: _ren, onChanged: (v) => setState(() => _ren = v)),
              ]),
            ),
            Row(children: [
              Expanded(
                child: GlowButton(
                  kind: BtnKind.dark,
                  label: 'Batal',
                  expand: true,
                  onPressed: _closeForm,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  icon: FontAwesomeIcons.floppyDisk,
                  label: _saving ? 'Menyimpan...' : 'Simpan',
                  expand: true,
                  onPressed: _saving ? null : _saveRule,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PickOpt {
  const _PickOpt(this.name, {this.sub, this.icon, this.color});
  final String name;
  final String? sub;
  final String? icon;
  final String? color;
}

/// Pilih banyak item / mutasi: ketik untuk mencari, ketuk untuk menambah.
class _TagPicker extends StatefulWidget {
  const _TagPicker({
    required this.selected,
    required this.source,
    required this.hint,
    required this.isItem,
    required this.iconUrlOf,
    required this.colorOf,
    required this.onChanged,
  });

  final List<String> selected;
  final List<_PickOpt> source;
  final String hint;
  final bool isItem;
  final String? Function(String name) iconUrlOf;
  final String Function(String name) colorOf;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String v) {
    v = v.trim();
    if (v.isEmpty) return;
    if (!widget.selected.any((x) => x.toLowerCase() == v.toLowerCase())) {
      widget.onChanged([...widget.selected, v]);
    }
    _ctl.clear();
    _focus.requestFocus();
  }

  void _remove(int i) {
    final l = [...widget.selected]..removeAt(i);
    widget.onChanged(l);
  }

  Widget _lead(String name, {String? iconId, String? color}) {
    if (widget.isItem) {
      final url = (iconId != null && iconId.isNotEmpty) ? dash.icons[iconId] : widget.iconUrlOf(name);
      return ItemIcon(url: url, size: 26);
    }
    final ms = parseMutationColor(catalogColorToMut(color ?? widget.colorOf(name)));
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ms.isNotEmpty ? mutationGradient(ms) : null,
        color: ms.isEmpty ? const Color(0x55FFFFFF) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final q = _ctl.text.trim().toLowerCase();
    final taken = sel.map((e) => e.toLowerCase()).toSet();
    final list = widget.source
        .where((o) => !taken.contains(o.name.toLowerCase()) && (q.isEmpty || o.name.toLowerCase().contains(q)))
        .take(60)
        .toList();
    final exact = widget.source.any((o) => o.name.toLowerCase() == q) || taken.contains(q);
    if (widget.isItem && _focus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dash.ensureIcons(list.map((o) => o.icon ?? ''));
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x59000000),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _focus.hasFocus ? Colors.white : C.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(spacing: 6, runSpacing: 6, children: [
                    for (var i = 0; i < sel.length; i++)
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _lead(sel[i]),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(sel[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ),
                          GestureDetector(
                            onTap: () => _remove(i),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(FontAwesomeIcons.xmark, size: 11, color: C.muted),
                            ),
                          ),
                        ]),
                      ),
                  ]),
                ),
              TextField(
                controller: _ctl,
                focusNode: _focus,
                cursorColor: Colors.white,
                style: const TextStyle(fontSize: 15),
                onSubmitted: (v) {
                  if (list.isNotEmpty) {
                    _add(list.first.name);
                  } else {
                    _add(v);
                  }
                },
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  hintText: sel.isEmpty ? widget.hint : 'Tambah lagi...',
                  hintStyle: const TextStyle(color: C.muted),
                ),
              ),
            ],
          ),
        ),
        if (_focus.hasFocus)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: const Color(0xCC0C0C0D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.glassBorder),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(6),
              children: [
                for (final o in list)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _add(o.name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      child: Row(children: [
                        _lead(o.name, iconId: o.icon, color: o.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(o.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if ((o.sub ?? '').isNotEmpty)
                          Text(o.sub!, style: const TextStyle(color: C.muted, fontSize: 11.5)),
                      ]),
                    ),
                  ),
                if (q.isNotEmpty && !exact)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _add(_ctl.text),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                      child: Row(children: [
                        const Icon(FontAwesomeIcons.plus, size: 12),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Tambah “${_ctl.text.trim()}”')),
                      ]),
                    ),
                  ),
                if (list.isEmpty && (q.isEmpty || exact))
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(widget.source.isEmpty ? 'Katalog masih kosong' : 'Tidak ada yang cocok',
                        style: const TextStyle(color: C.muted)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
