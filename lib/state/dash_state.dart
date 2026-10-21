import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../models/item.dart';

num? _num(dynamic v) {
  if (v is num) return v;
  if (v == null) return null;
  return num.tryParse('$v');
}

dynamic _strip(dynamic v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        if (e.key != 'updated_at') e.key: _strip(e.value),
    };
  }
  if (v is List) return v.map(_strip).toList();
  return v;
}

class BotInfo {
  const BotInfo(this.status, {this.age, this.timer, this.stock});
  final String status; // online | hopping | offline
  final int? age;
  final double? timer;
  final int? stock;

  factory BotInfo.from(dynamic m) {
    if (m is Map) {
      return BotInfo(
        '${m['status'] ?? 'offline'}',
        age: _num(m['age'])?.toInt(),
        timer: _num(m['timer'])?.toDouble(),
        stock: _num(m['stock'])?.toInt(),
      );
    }
    return const BotInfo('offline');
  }
}

/// Satu-satunya sumber data dashboard (padanan variabel S, BOTS, IC di index.php).
/// Polling ui_state tiap 4 detik; UI hanya dibangun ulang kalau datanya berubah.
class DashState extends ChangeNotifier {
  String user = '';
  List<String> users = [];
  Map<String, BotInfo> bots = {};
  bool loaded = false;
  bool connected = false;
  String? error;

  int tokens = 0;
  int soldCount = 0;
  double soldSum = 0;
  int max = 10;
  int reserved = 0;
  int timerMin = 0;
  int? invAge;
  List<Item> booth = [];
  List<Item> inv = [];
  List<Map<String, dynamic>> queue = [];
  List<Map<String, dynamic>> sales = [];

  double? botTimer;
  DateTime botTimerAt = DateTime.now();

  final Set<String> sent = {};
  final Map<String, String> icons = {}; // iconId -> url
  final Map<String, String> nameIcons = {}; // nama dasar (lowercase) -> iconId
  final Set<String> _pending = {};

  Timer? _poll;
  bool paused = false;
  bool _loading = false;
  String _key = '';
  String _sig = '';

  BotInfo get bot => bots[user] ?? const BotInfo('offline');
  int get used => booth.length + reserved;
  bool get full => used >= max;

  Future<void> start() async {
    if (_poll != null) return;
    final p = await SharedPreferences.getInstance();
    user = p.getString('u') ?? '';
    await load(force: true);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!paused) load();
    });
  }

  void setPaused(bool v) {
    paused = v;
    if (!v) load();
  }

  Future<void> selectUser(String u) async {
    if (u == user) return;
    user = u;
    sent.clear();
    _key = '';
    _sig = '';
    notifyListeners();
    await load(force: true);
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    _loading = true;
    try {
      final d = await Api.call('ui_state', username: user);
      if (d['status'] != 'ok') throw ApiException('${d['message'] ?? 'error'}');

      final nb = <String, BotInfo>{};
      final br = d['bots'];
      if (br is Map) br.forEach((k, v) => nb['$k'] = BotInfo.from(v));
      final us = d['users'] is List
          ? (d['users'] as List).map((e) => '$e').toList()
          : <String>[];

      final rest = Map<String, dynamic>.from(d)
        ..remove('bots')
        ..remove('inv_age');
      final key = jsonEncode(_strip(rest));
      final changed = force || !loaded || key != _key;

      user = '${d['user'] ?? ''}';
      users = us;
      bots = nb;
      invAge = _num(d['inv_age'])?.toInt();
      botTimer = bot.timer;
      botTimerAt = DateTime.now();
      error = null;
      connected = true;

      if (changed) {
        _key = key;
        _parse(d);
      }
      loaded = true;

      final sig =
          '$user|${users.join(',')}|${nb.entries.map((e) => '${e.key}:${e.value.status}').join(',')}|${ago(invAge)}|1';
      final sigChanged = sig != _sig;
      _sig = sig;
      if (changed || sigChanged) notifyListeners();

      if (changed) {
        SharedPreferences.getInstance().then((p) => p.setString('u', user));
        ensureIcons([...booth, ...inv].map((e) => e.iconId));
      }
    } catch (e) {
      final msg = e.toString();
      final was = error;
      error = msg;
      connected = false;
      _sig = '';
      if (was != msg) notifyListeners();
    } finally {
      _loading = false;
    }
  }

  List<Item> _items(dynamic v) => v is List
      ? v.whereType<Map>().map((e) => Item(Map<String, dynamic>.from(e))).toList()
      : <Item>[];

  List<Map<String, dynamic>> _maps(dynamic v) => v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];

  void _parse(Map<String, dynamic> d) {
    tokens = _num(d['tokens'])?.round() ?? 0;
    soldCount = _num(d['sold_count'])?.round() ?? 0;
    soldSum = _num(d['sold_sum'])?.toDouble() ?? 0;
    max = _num(d['max'])?.toInt() ?? 10;
    reserved = _num(d['reserved'])?.toInt() ?? 0;
    timerMin = _num(d['timer_min'])?.toInt() ?? 0;
    booth = _items(d['booth']);
    inv = _items(d['inv']);
    queue = _maps(d['queue']);
    sales = _maps(d['sales']);
    for (final x in [...inv, ...booth]) {
      final k = x.baseName.toLowerCase();
      if (x.iconId.isNotEmpty && !nameIcons.containsKey(k)) {
        nameIcons[k] = x.iconId;
      }
    }
  }

  /// Ambil URL ikon (get_item_icons_batch), 50 id per permintaan.
  Future<void> ensureIcons(Iterable<String> ids) async {
    final need = ids
        .where((a) => a.isNotEmpty && !icons.containsKey(a) && !_pending.contains(a))
        .toSet()
        .toList();
    for (var i = 0; i < need.length; i += 50) {
      final chunk = need.sublist(i, i + 50 > need.length ? need.length : i + 50);
      _pending.addAll(chunk);
      try {
        final d = await Api.call('get_item_icons_batch',
            query: {'ids': chunk.join(',')});
        final data = d['data'];
        if (data is List) {
          for (final t in data) {
            if (t is Map && t['imageUrl'] != null) {
              icons['${t['targetId']}'] = '${t['imageUrl']}';
            }
          }
          notifyListeners();
        }
      } catch (_) {}
      _pending.removeAll(chunk);
    }
  }

  Future<Map<String, dynamic>> cmd(Map<String, dynamic> body) =>
      Api.call('ui_cmd', body: {...body, 'username': user});

  /// item yang perintahnya sudah dikirim: tampil "Proccess/Sending" selama 25 dtk
  void markSent(Iterable<String> ids) {
    for (final k in ids) {
      sent.add(k);
      Timer(const Duration(seconds: 25), () {
        sent.remove(k);
        notifyListeners();
      });
    }
    notifyListeners();
  }
}

final dash = DashState();
