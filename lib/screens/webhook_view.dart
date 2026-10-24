import 'package:flutter/material.dart';
import '../core/fa.dart';
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
import '../widgets/page_title.dart';
import '../widgets/pill.dart';
import '../widgets/reveal.dart';
import '../widgets/toast.dart';

const kWhRarity = <DropOpt>[
  DropOpt('', 'Semua rarity'),
  DropOpt('uncommon', 'Uncommon ke atas'),
  DropOpt('rare', 'Rare ke atas'),
  DropOpt('epic', 'Epic ke atas'),
  DropOpt('legendary', 'Legendary ke atas'),
  DropOpt('mythic', 'Mythic ke atas'),
  DropOpt('secret', 'Secret ke atas'),
  DropOpt('forgotten', 'Forgotten saja'),
];

const kWhKind = <DropOpt>[
  DropOpt('sale', 'Item Terjual'),
  DropOpt('find', 'Find Items'),
];

List<Map<String, dynamic>> mapsOf(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

bool truthy(dynamic v) => v == true || (v is num && v != 0) || v == '1';

/// Webhook Discord: notifikasi item terjual & Find Items.
class WebhookView extends StatefulWidget {
  const WebhookView({super.key, required this.active});
  final bool active;

  @override
  State<WebhookView> createState() => _WebhookViewState();
}

class _WebhookViewState extends State<WebhookView> {
  Map<String, dynamic>? _wh;
  String? _err;
  bool _form = false;
  bool _saving = false;
  bool _busy = false;
  int _editId = 0;
  String _kind = 'sale', _bot = '', _rar = '', _hint = '';
  bool _thumb = true, _enabled = true;
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _min = TextEditingController();
  final _dn = TextEditingController();
  final _av = TextEditingController();
  final _mn = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(covariant WebhookView old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _url, _min, _dn, _av, _mn]) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> get _list => mapsOf(_wh?['webhooks']);
  List<String> get _bots => ((_wh?['bots'] as List?) ?? []).map((e) => '$e').toList();

  void _toast(String m, {IconData icon = FaS.circleCheck}) {
    if (mounted) showToast(context, m, icon: icon);
  }

  Future<void> _load() async {
    try {
      final d = await Api.call('wh_list', username: dash.user);
      if (d['status'] != 'ok') throw ApiException('${d['message'] ?? 'error'}');
      if (mounted) {
        setState(() {
          _wh = d;
          _err = null;
        });
      }
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

  void _open(Map<String, dynamic>? w) {
    setState(() {
      _form = true;
      _editId = w == null ? 0 : numOf(w['id']).toInt();
      _name.text = w == null ? '' : strOf(w['name']);
      _url.clear();
      _hint = w == null ? '' : 'Tersimpan: ${strOf(w['hint'])}';
      _kind = w == null ? 'sale' : strOf(w['kind']);
      _bot = w == null ? '' : strOf(w['bot']);
      _rar = w == null ? '' : strOf(w['min_rarity']);
      final mp = w == null ? 0 : numOf(w['min_price']);
      _min.text = mp > 0 ? '${mp.round()}' : '';
      _dn.text = w == null ? 'Preman Plaza' : strOf(w['display_name']);
      _av.text = w == null ? '' : strOf(w['avatar_url']);
      _mn.text = w == null ? '' : strOf(w['mention']);
      _thumb = w == null ? true : numOf(w['show_thumb']) != 0;
      _enabled = w == null ? true : numOf(w['enabled']) != 0;
    });
  }

  Future<void> _save() async {
    final url = _url.text.trim();
    if (_editId == 0 && url.isEmpty) {
      _toast('Isi URL webhook dulu', icon: FontAwesomeIcons.circleExclamation);
      return;
    }
    final body = <String, dynamic>{
      'id': _editId,
      'kind': _kind,
      'name': _name.text,
      'bot': _bot,
      'min_rarity': _rar,
      'min_price': double.tryParse(_min.text.trim()) ?? 0,
      'display_name': _dn.text,
      'avatar_url': _av.text,
      'mention': _mn.text,
      'show_thumb': _thumb ? 1 : 0,
      'enabled': _enabled ? 1 : 0,
      if (url.isNotEmpty) 'url': url,
    };
    setState(() => _saving = true);
    final r = await _post('wh_save', body);
    if (mounted) setState(() => _saving = false);
    if (r == null) return;
    if (r['status'] != 'ok') {
      _toast('${r['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.triangleExclamation);
      return;
    }
    if (mounted) setState(() => _form = false);
    _toast('${r['message'] ?? 'Tersimpan'}');
    _load();
  }

  Future<void> _toggle(Map<String, dynamic> w) async {
    final on = numOf(w['enabled']) != 0;
    final r = await _post('wh_save', {'id': numOf(w['id']).toInt(), 'enabled': on ? 0 : 1});
    if (r == null) return;
    if (r['status'] != 'ok') {
      _toast('${r['message'] ?? 'Gagal'}', icon: FontAwesomeIcons.triangleExclamation);
    } else {
      _toast(on ? 'Webhook dinonaktifkan' : 'Webhook diaktifkan');
    }
    _load();
  }

  Future<void> _test(Map<String, dynamic> w) async {
    _toast('Mengirim tes...', icon: FaS.paperPlane);
    final r = await _post('wh_test', {'id': numOf(w['id']).toInt()});
    if (r == null) return;
    _toast('${r['message'] ?? ''}',
        icon: r['status'] == 'ok'
            ? FaS.circleCheck
            : FontAwesomeIcons.triangleExclamation);
    _load();
  }

  Future<void> _delete(Map<String, dynamic> w) async {
    if (_busy) return;
    _busy = true;
    final ok = await confirmBox(
      context,
      title: 'Hapus webhook?',
      icon: FaS.trashCan,
      danger: true,
      okIcon: FaS.trashCan,
      okLabel: 'Ya, Hapus',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x59000000),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(strOf(w['name']), style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(strOf(w['hint']), style: const TextStyle(color: C.muted, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Notifikasi ke webhook ini akan berhenti.',
              style: TextStyle(color: C.muted, fontSize: 13.6)),
        ],
      ),
    );
    _busy = false;
    if (!ok) return;
    final r = await _post('wh_delete', {'id': numOf(w['id']).toInt()});
    if (r == null) return;
    _toast('${r['message'] ?? 'Dihapus'}', icon: FaS.trashCan);
    _load();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final list = _list;
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(14, 10, 14, 90 + bottom),
        children: [
          const PageTitle(FontAwesomeIcons.discord, 'Webhook'),
          const SizedBox(height: 14),
          if (_wh == null && _err != null)
            EmptyState(FontAwesomeIcons.triangleExclamation, 'Gagal memuat webhook: $_err')
          else if (_wh == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (_form)
            _formCard()
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: GlowButton(
                icon: FontAwesomeIcons.plus,
                label: 'Add Webhook',
                onPressed: () => _open(null),
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const EmptyState(FaS.bellSlash,
                  'Belum ada webhook. Tambahkan satu untuk menerima notifikasi item terjual di Discord.')
            else
              for (var i = 0; i < list.length; i++) _card(list[i], i),
          ],
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> w, int i) {
    final id = numOf(w['id']).toInt();
    final on = numOf(w['enabled']) != 0;
    final isFind = strOf(w['kind']) == 'find';
    final ls = w['last_status'];
    final okS = ls != null && numOf(ls) >= 200 && numOf(ls) < 300;
    final t = ago(w['last_ago'] == null ? null : numOf(w['last_ago']).toInt());
    final rarLabel = kWhRarity
        .firstWhere((o) => o.value == strOf(w['min_rarity']),
            orElse: () => DropOpt('', strOf(w['min_rarity'])))
        .label;

    final InlineSpan status = ls == null
        ? const TextSpan(text: 'Belum pernah mengirim')
        : okS
            ? TextSpan(children: [
                const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(FaS.circleCheck, size: 11, color: C.green)),
                TextSpan(text: ' Terkirim $t lalu', style: const TextStyle(color: C.green)),
              ])
            : TextSpan(children: [
                const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(FontAwesomeIcons.circleExclamation, size: 11, color: C.red)),
                TextSpan(
                  text:
                      ' Gagal${numOf(ls) > 0 ? ' (HTTP ${numOf(ls).toInt()})' : ''}: ${strOf(w['last_error']).isEmpty ? 'tidak diketahui' : strOf(w['last_error'])} · $t lalu',
                  style: const TextStyle(color: C.red),
                ),
              ]);

    final tags = <Widget>[
      if (isFind)
        Pill(FontAwesomeIcons.magnifyingGlass,
            'Find Items${numOf(_wh?['find_id']).toInt() == id ? ' · dipakai' : ''}')
      else ...[
        const Pill(FontAwesomeIcons.bagShopping, 'Item Terjual'),
        Pill(FontAwesomeIcons.robot, strOf(w['bot']).isEmpty ? 'Semua bot' : strOf(w['bot'])),
      ],
      if (strOf(w['min_rarity']).isNotEmpty) Pill(FaS.gem, rarLabel),
      if (numOf(w['min_price']) > 0)
        Pill(FontAwesomeIcons.coins, '≥ ${fmt(numOf(w['min_price']))}', gold: true),
      if (strOf(w['mention']).isNotEmpty) const Pill(FontAwesomeIcons.at, 'Mention'),
    ];

    return Reveal(
      index: i,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassDim(
          opacity: on ? 1 : 0.55,
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7289DA), Color(0xFF4752C4)],
                      ),
                    ),
                    child: const Icon(FontAwesomeIcons.discord, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(strOf(w['name']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      Text(strOf(w['hint']),
                          style: const TextStyle(color: C.muted, fontSize: 12)),
                    ]),
                  ),
                  GlassSwitch(value: on, onChanged: (_) => _toggle(w)),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: tags),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(children: [
                    status,
                    TextSpan(text: ' · ${fmt(numOf(w['sent_count']))} terkirim'),
                  ]),
                  style: const TextStyle(color: C.muted, fontSize: 12.5, height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: GlowButton(
                      kind: BtnKind.dark,
                      height: 40,
                      radius: 13,
                      expand: true,
                      icon: FaS.paperPlane,
                      label: 'Tes',
                      onPressed: () => _test(w),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlowButton(
                      kind: BtnKind.dark,
                      height: 40,
                      radius: 13,
                      expand: true,
                      icon: FontAwesomeIcons.pen,
                      label: 'Edit',
                      onPressed: () => _open(w),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlowButton(
                    kind: BtnKind.trash,
                    height: 40,
                    width: 52,
                    radius: 13,
                    padding: EdgeInsets.zero,
                    icon: FaS.trashCan,
                    onPressed: () => _delete(w),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t, Widget child, {String? note}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
          child,
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(note, style: const TextStyle(color: C.muted, fontSize: 12)),
            ),
        ]),
      );

  Widget _sw(String t, bool v, ValueChanged<bool> f) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))),
          GlassSwitch(value: v, onChanged: f),
        ]),
      );

  Widget _formCard() {
    final isFind = _kind == 'find';
    final bots = _bots;
    final botOpts = <DropOpt>[
      const DropOpt('', 'Semua bot'),
      ...(_bot.isNotEmpty && !bots.contains(_bot) ? [...bots, _bot] : bots)
          .map((b) => DropOpt(b, b)),
    ];
    return Reveal(
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(FontAwesomeIcons.discord, size: 16),
              const SizedBox(width: 10),
              Text(_editId == 0 ? 'Tambah Webhook' : 'Edit Webhook',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
            ]),
            const SizedBox(height: 18),
            _lbl('Jenis',
                GlassDropdown(value: _kind, options: kWhKind, onChanged: (v) => setState(() => _kind = v))),
            _lbl('Nama', GlassInput(controller: _name, hint: 'Contoh: Channel Penjualan')),
            _lbl(
              'URL Webhook Discord',
              GlassInput(
                controller: _url,
                hint: _editId == 0
                    ? 'https://discord.com/api/webhooks/...'
                    : 'Kosongkan jika URL tidak diganti',
              ),
              note: _hint,
            ),
            if (!isFind) ...[
              _lbl('Bot',
                  GlassDropdown(value: _bot, options: botOpts, onChanged: (v) => setState(() => _bot = v))),
              _lbl('Rarity minimum',
                  GlassDropdown(value: _rar, options: kWhRarity, onChanged: (v) => setState(() => _rar = v))),
              _lbl('Harga minimum (token)',
                  GlassInput(controller: _min, number: true, hint: '0 = semua harga')),
            ],
            _lbl('Nama pengirim', GlassInput(controller: _dn, hint: 'Preman Plaza')),
            _lbl('Avatar URL (opsional)', GlassInput(controller: _av, hint: 'https://...')),
            _lbl('Mention (opsional)',
                GlassInput(controller: _mn, hint: '<@id_user>, <@&id_role> atau @everyone')),
            _sw('Tampilkan thumbnail item', _thumb, (v) => setState(() => _thumb = v)),
            _sw('Webhook aktif', _enabled, (v) => setState(() => _enabled = v)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: GlowButton(
                  kind: BtnKind.dark,
                  label: 'Batal',
                  expand: true,
                  onPressed: () => setState(() => _form = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  icon: FaS.floppyDisk,
                  label: _saving ? 'Menyimpan...' : 'Simpan',
                  expand: true,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
