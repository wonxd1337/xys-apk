double numOf(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is bool) return v ? 1 : 0;
  return double.tryParse('${v ?? ''}') ?? 0;
}

String strOf(dynamic v) => v == null ? '' : '$v';

final _reShiny = RegExp(r'\bshiny\b', caseSensitive: false);
final _reWs = RegExp(r'\s+');

/// Item booth / inventaris. Aturan nama = salinan helper di index.php
/// (sizeOf, mutNm, isSh, mutOn, pfx, baseOf, nameText).
class Item {
  Item(this.raw);
  final Map<String, dynamic> raw;

  String get uuid => strOf(raw['uuid']);
  String get name => strOf(raw['name']);
  double get price => numOf(raw['price']);
  double get rap => numOf(raw['rap']);
  double get weight => numOf(raw['weight']);
  bool get hasWeight => weight >= 0.01;

  String get rarity {
    final r = strOf(raw['rarity']);
    return r.isEmpty ? 'common' : r.toLowerCase();
  }

  String get mutationRaw => strOf(raw['mutation']);
  String get mutationColor => strOf(raw['mutation_color']);

  String get category {
    final c = strOf(raw['category']);
    if (c.isNotEmpty) return c;
    final t = strOf(raw['type']);
    return t.isEmpty ? 'Lainnya' : t;
  }

  /// id aset ikon (angka) untuk get_item_icons_batch
  String get iconId =>
      RegExp(r'\d+').firstMatch(strOf(raw['icon']))?.group(0) ?? '';

  /// '', 'big', atau 'max'
  String get size {
    final s = strOf(raw['size_category']).toLowerCase();
    return (s == 'max' || s == 'big') ? s : '';
  }

  bool get isMax => size == 'max';

  String get mutName =>
      mutationRaw.replaceAll(_reShiny, '').replaceAll(_reWs, ' ').trim();

  bool get isShiny => numOf(raw['shiny']) != 0 || _reShiny.hasMatch(mutationRaw);

  bool get mutOn => mutName.isNotEmpty && mutName.toLowerCase() != 'normal';

  String get prefix => (isShiny ? 'Shiny ' : '') + (size.isNotEmpty ? 'Big ' : '');

  String get _cn {
    var n = name;
    if (size.isNotEmpty) {
      n = n
          .replaceFirst(RegExp(r'^Big\s+'), '')
          .replaceFirst(RegExp(r'\s*\[MAX\]'), '');
    }
    return n.replaceFirst(
        RegExp(r'\s*\[[\d.,]+\s*kg\]\s*$', caseSensitive: false), '');
  }

  String get baseName {
    final b = strOf(raw['base_name']);
    return (b.isNotEmpty ? b : _cn)
        .replaceFirst(RegExp(r'^shiny\s+', caseSensitive: false), '');
  }

  String get nameText =>
      (mutOn ? '${mutName.toUpperCase()} ' : '') +
      prefix +
      baseName +
      (isMax ? ' [MAXTON]' : '');
}

/// Riwayat penjualan lama belum punya kolom detail: dibaca dari teks item_name (padanan hx() di index.php)
Item historyItem(Map<String, dynamic> x, Map<String, String> nameIcons) {
  final nm = strOf(x['item_name']);
  final o = Map<String, dynamic>.from(x);
  if (strOf(o['base_name']).isEmpty) {
    o['base_name'] = nm
        .replaceFirst(RegExp(r'\s*\[[\d.,]+\s*kg\]\s*$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*\[MAX\]', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^Big\s+'), '');
    if (strOf(o['size_category']).isEmpty) {
      o['size_category'] = RegExp(r'\[MAX\]', caseSensitive: false).hasMatch(nm)
          ? 'Max'
          : (RegExp(r'^Big\s').hasMatch(nm) ? 'Big' : '');
    }
  }
  if (!(numOf(o['weight']) > 0)) {
    final m = RegExp(r'\[([\d.,]+)\s*kg\]', caseSensitive: false).firstMatch(nm);
    o['weight'] = m == null ? 0 : (double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0);
  }
  if (strOf(o['icon']).isEmpty) {
    o['icon'] = nameIcons[strOf(o['base_name']).toLowerCase()] ?? '';
  }
  o['name'] = nm;
  return Item(o);
}
