import 'package:flutter/material.dart';
import '../core/fa.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/item.dart';
import 'gradient_text.dart';

/// Ikon item (thumbnail Roblox). Fallback: ikon permata.
class ItemIcon extends StatelessWidget {
  const ItemIcon({super.key, this.url, this.size = 46});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(FaS.gem, size: size * 0.38, color: C.muted);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        color: const Color(0x99000000),
        gradient: const RadialGradient(
          colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
          stops: [0, 0.7],
        ),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: url == null
            ? Center(child: fallback)
            : Image.network(
                url!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(child: fallback),
              ),
      ),
    );
  }
}

/// Label mutasi: gradient dari mutation_color, border + latar transparan.
class MutTag extends StatelessWidget {
  const MutTag({super.key, required this.name, required this.colorStr, this.fontSize = 12});
  final String name;
  final String colorStr;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final ms = parseMutationColor(colorStr);
    final mid = ms.isNotEmpty ? ms[ms.length >> 1].color : const Color(0xFFFFD27A);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
      height: 1.3,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: mid.withAlpha(0x99)),
        color: ms.isEmpty ? const Color(0x22FFD27A) : null,
        gradient: ms.isNotEmpty ? mutationGradient(ms, alpha: 0x2E) : null,
      ),
      child: ms.isNotEmpty
          ? GradientText(name.toUpperCase(), gradient: mutationGradient(ms), style: style)
          : Text(name.toUpperCase(), style: style.copyWith(color: const Color(0xFFFFD27A))),
    );
  }
}

class MaxLabel extends StatelessWidget {
  const MaxLabel({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(top: compact ? 0 : 5),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFBDBDBD)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x77FFFFFF), blurRadius: 12)],
        ),
        child: const Text('MAXTON',
            style: TextStyle(
                color: Colors.black,
                fontSize: 9.9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                height: 1.3)),
      );
}

/// [MUTASI] [Shiny][Big] Nama  (+ label MAXTON), warna sesuai rarity.
class ItemName extends StatelessWidget {
  const ItemName(this.item, {super.key, this.fontSize = 15, this.maxLines = 2});
  final Item item;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final rc = rarityColor(item.rarity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              if (item.mutOn)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: MutTag(
                        name: item.mutName,
                        colorStr: item.mutationColor,
                        fontSize: fontSize * 0.8),
                  ),
                ),
              TextSpan(text: item.prefix + item.baseName),
            ],
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: rc, fontWeight: FontWeight.w800, fontSize: fontSize, height: 1.25),
        ),
        if (item.isMax) const MaxLabel(),
      ],
    );
  }
}

/// 1.500.000 (gradient emas) + ikon koin
class PriceText extends StatelessWidget {
  const PriceText(this.price, {super.key, this.fontSize = 16});
  final num price;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientText(fmt(price),
              gradient: goldGradient,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: fontSize)),
          const SizedBox(width: 5),
          Icon(FontAwesomeIcons.coins, size: fontSize * 0.8, color: const Color(0xFFFFC400)),
        ],
      );
}

const _mutedStyle = TextStyle(color: C.muted, fontSize: 13.6, height: 1.35);

/// Ringkasan 1 item untuk isi dialog (harga + catatan opsional).
class ItemSummary extends StatelessWidget {
  const ItemSummary({super.key, required this.item, this.iconUrl, this.price, this.note});
  final Item item;
  final String? iconUrl;
  final num? price;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(Row(
          children: [
            ItemIcon(url: iconUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ItemName(item),
                  if (item.hasWeight)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text.rich(TextSpan(children: [
                        const WidgetSpan(
                            child: Icon(FontAwesomeIcons.weightHanging, size: 10, color: C.muted)),
                        TextSpan(text: ' ${fw(item.weight)}'),
                      ]), style: const TextStyle(color: C.muted, fontSize: 12.5)),
                    ),
                ],
              ),
            ),
          ],
        )),
        if (price != null && price! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [
              const Text('Harga: ', style: _mutedStyle),
              PriceText(price!),
            ]),
          ),
        if (note != null && note!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(note!, style: _mutedStyle)),
      ],
    );
  }
}

/// Ringkasan beberapa item (mode Pilih).
class ManySummary extends StatelessWidget {
  const ManySummary({super.key, required this.items, this.price, this.note, this.headline, this.priceLabel = 'Harga tiap item: '});
  final List<Item> items;
  final num? price;
  final String? note;
  final String priceLabel;
  final String? headline;

  @override
  Widget build(BuildContext context) {
    final names = items.take(3).map((e) => e.nameText).join(', ');
    final more = items.length > 3 ? ' +${items.length - 3} lainnya' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline ?? '${items.length} item dipilih',
                style: const TextStyle(fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 3),
            Text('$names$more', style: const TextStyle(color: C.muted, fontSize: 12.5)),
          ],
        )),
        if (price != null && price! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [Text(priceLabel, style: _mutedStyle), PriceText(price!)]),
          ),
        if (note != null && note!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(note!, style: _mutedStyle)),
      ],
    );
  }
}

Widget _box(Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x59000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: child,
    );

/// RAP · berat · selisih vs RAP (untuk kartu temuan Find Items)
class ItemFooter extends StatelessWidget {
  const ItemFooter(this.item, {super.key});
  final Item item;

  @override
  Widget build(BuildContext context) {
    final rap = item.rap, pr = item.price;
    final df = rap > 0 ? ((pr / rap - 1) * 100).round() : null;
    const lab = TextStyle(color: C.muted, fontSize: 10.9);
    const val = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700);
    const sep = TextStyle(color: Color(0x80FFFFFF), fontSize: 12.5);
    final parts = <InlineSpan>[];
    void add(List<InlineSpan> p) {
      if (parts.isNotEmpty) parts.add(const TextSpan(text: '  ·  ', style: sep));
      parts.addAll(p);
    }

    if (rap > 0) add([const TextSpan(text: 'RAP ', style: lab), TextSpan(text: fmt(rap), style: val)]);
    if (item.hasWeight) add([TextSpan(text: fw(item.weight), style: val)]);
    if (df != null) {
      add([
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(df >= 0 ? FontAwesomeIcons.arrowUp : FontAwesomeIcons.arrowDown, size: 9),
        ),
        TextSpan(text: ' ${df.abs()}%', style: val),
      ]);
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text.rich(TextSpan(children: parts), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
