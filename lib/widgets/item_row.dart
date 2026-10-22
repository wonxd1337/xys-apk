import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/item.dart';
import 'glass_card.dart';
import 'item_widgets.dart';
import 'reveal.dart';

/// Lencana harga kuning (.bd.pr)
class PriceBadge extends StatelessWidget {
  const PriceBadge(this.price, {super.key});
  final num price;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x21FFC400),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0x73FFC400)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(FontAwesomeIcons.coins, size: 11, color: Color(0xFFFFD24A)),
          const SizedBox(width: 6),
          Text(fmt(price),
              style: const TextStyle(
                  color: Color(0xFFFFD24A), fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
      );
}

/// Ikon kecil + teks untuk baris keterangan
InlineSpan metaPart(IconData icon, String text) => TextSpan(children: [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(icon, size: 10, color: C.muted),
        ),
      ),
      TextSpan(text: text),
    ]);

/// Gabungkan bagian keterangan dengan pemisah " · "
InlineSpan joinMeta(List<InlineSpan> parts) {
  final out = <InlineSpan>[];
  for (var i = 0; i < parts.length; i++) {
    if (i > 0) out.add(const TextSpan(text: ' · '));
    out.add(parts[i]);
  }
  return TextSpan(children: out);
}

/// Baris item (.rw): dipakai Antrian Jual dan Riwayat Penjualan.
class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.item,
    required this.meta,
    this.iconUrl,
    this.price,
    this.actions = const [],
    this.index = 0,
  });

  final Item item;
  final InlineSpan meta;
  final String? iconUrl;
  final num? price;
  final List<Widget> actions;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      index: index,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ItemIcon(url: iconUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ItemName(item, maxLines: 1),
                  const SizedBox(height: 3),
                  Text.rich(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: C.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (price != null) ...[const SizedBox(width: 8), PriceBadge(price!)],
            for (final a in actions) ...[const SizedBox(width: 6), a],
          ],
        ),
      ),
    ));
  }
}
