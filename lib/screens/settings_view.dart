import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/api.dart';
import '../core/fx.dart';
import '../core/sfx.dart';
import '../core/theme.dart';
import '../state/dash_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_input.dart';
import '../widgets/glass_switch.dart';
import '../widgets/glow_button.dart';
import '../widgets/toast.dart';

/// URL server + token disimpan di HP. Pindah server cukup ganti di sini,
/// tanpa build ulang APK.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final _url = TextEditingController(text: Api.baseUrl);
  late final _tok = TextEditingController(text: Api.token);
  bool _busy = false;
  bool _sfx = Sfx.enabled;

  @override
  void dispose() {
    _url.dispose();
    _tok.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Api.save(_url.text, _tok.text);
    try {
      final d = await Api.call('ui_state', username: '');
      if (!mounted) return;
      if (d['status'] == 'ok') {
        showToast(context, 'Terhubung (bot: ${d['user'] ?? '-'})');
      } else {
        showToast(context, '${d['message'] ?? 'Respons error'}',
            icon: FontAwesomeIcons.triangleExclamation);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, '$e', icon: FontAwesomeIcons.triangleExclamation);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    await Api.save(_url.text, _tok.text);
    dash.load(force: true);
    if (!mounted) return;
    showToast(context, 'Tersimpan');
    widget.onSaved();
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      );

  @override
  Widget build(BuildContext context) {
    const note = TextStyle(color: C.muted, fontSize: 12.5, height: 1.35);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 4, 0, 14),
          child: Row(children: [
            Icon(FontAwesomeIcons.gear, size: 16),
            SizedBox(width: 9),
            Text('Pengaturan', style: TextStyle(fontSize: 17.6, fontWeight: FontWeight.w800)),
          ]),
        ),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('URL Server'),
              GlassInput(
                controller: _url,
                hint: 'http://1.2.3.4/folder  atau  https://api.domain.com',
                action: TextInputAction.next,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6, bottom: 14),
                child: Text(
                    'Alamat folder tempat api.php berada, tanpa "/api.php". Boleh http atau https. Pindah server? Ganti saja di sini.',
                    style: note),
              ),
              _label('Token (opsional)'),
              GlassInput(controller: _tok, hint: 'Kosongkan kalau api.php belum pakai token', obscure: true),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Isi sama persis dengan APP_SECRET di auth.php (kalau auth.php dipasang).', style: note),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: GlowButton(
                    kind: BtnKind.dark,
                    icon: FontAwesomeIcons.plugCircleBolt,
                    label: _busy ? 'Menguji...' : 'Tes Koneksi',
                    expand: true,
                    onPressed: _busy ? null : _test,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlowButton(
                    icon: FontAwesomeIcons.check,
                    label: 'Simpan',
                    expand: true,
                    onPressed: _save,
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            const Icon(FontAwesomeIcons.volumeHigh, size: 15),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Suara klik', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            GlassSwitch(
              value: _sfx,
              onChanged: (v) {
                setState(() => _sfx = v);
                Sfx.setEnabled(v);
              },
            ),
          ]),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: ValueListenableBuilder<bool>(
            valueListenable: Fx.light,
            builder: (_, light, __) => Row(children: [
              const Icon(FontAwesomeIcons.bolt, size: 15),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mode ringan', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Kurangi blur dan matikan latar bergerak kalau terasa patah-patah.',
                      style: TextStyle(color: C.muted, fontSize: 12, height: 1.3)),
                ]),
              ),
              const SizedBox(width: 10),
              GlassSwitch(value: light, onChanged: (v) => Fx.setLight(v)),
            ]),
          ),
        ),
      ],
    );
  }
}
