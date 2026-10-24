import 'package:flutter/material.dart';
import '../core/fa.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/item.dart';
import 'glass_card.dart';
import 'glass_input.dart';
import 'glow_button.dart';
import 'reveal.dart';
import 'item_widgets.dart';
import 'spin_border.dart';

/// Kartu item booth / inventaris (tata letak mobile index.php).
class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.isBooth,
    required this.full,
    required this.sent,
    required this.selMode,
    required this.selected,
    required this.dimmed,
    this.index = 0,
    this.iconUrl,
    this.priceCtl,
    this.onTapSelect,
    this.onSell,
    this.onSkip,
    this.onEdit,
    this.onUnlist,
  });

  final Item item;
  final bool isBooth;
  final bool full;
  final bool sent;
  final bool selMode;
  final bool selected;
  final bool dimmed;
  final int index;
  final String? iconUrl;
  final TextEditingController? priceCtl;
  final VoidCallback? onTapSelect;
  final VoidCallback? onSell;
  final VoidCallback? onSkip;
  final VoidCallback? onEdit;
  final VoidCallback? onUnlist;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _pressed = false;

  Widget _footer(Item it) {
    final rap = it.rap, pr = it.price;
    final df = widget.isBooth && rap > 0 ? ((pr / rap - 1) * 100).round() : null;
    const lab = TextStyle(color: C.muted, fontSize: 10.9);
    const val = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700);
    const sep = TextStyle(color: Color(0x80FFFFFF), fontSize: 12.5);
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'RAP ', style: lab),
          TextSpan(text: fmt(rap), style: val),
          if (it.hasWeight) ...[
            const TextSpan(text: '  ·  ', style: sep),
            TextSpan(text: fw(it.weight), style: val),
          ],
          if (df != null) ...[
            const TextSpan(text: '  ·  ', style: sep),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                df >= 0 ? FontAwesomeIcons.arrowUp : FontAwesomeIcons.arrowDown,
                size: 9,
              ),
            ),
            TextSpan(text: ' ${df.abs()}%', style: val),
          ],
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _actions() {
    final w = widget;
    if (w.isBooth) {
      return Row(children: [
        Expanded(
          child: GlowButton(
            kind: BtnKind.dark,
            height: 40,
            radius: 13,
            expand: true,
            icon: w.sent ? FontAwesomeIcons.hourglassHalf : FontAwesomeIcons.pen,
            label: w.sent ? 'Proccess' : 'Edit Price',
            onPressed: w.sent ? null : w.onEdit,
          ),
        ),
        const SizedBox(width: 8),
        GlowButton(
          kind: BtnKind.trash,
          height: 40,
          width: 52,
          radius: 13,
          padding: EdgeInsets.zero,
          icon: w.sent ? FontAwesomeIcons.hourglassHalf : FaS.trashCan,
          onPressed: w.sent ? null : w.onUnlist,
        ),
      ]);
    }
    return Row(children: [
      Expanded(
        child: GlassInput(
          controller: w.priceCtl!,
          hint: 'Price',
          number: true,
          onSubmitted: (_) => w.sent ? null : w.onSell?.call(),
        ),
      ),
      const SizedBox(width: 8),
      GlowButton(
        height: 40,
        radius: 13,
        icon: w.sent
            ? FontAwesomeIcons.check
            : (w.full ? FontAwesomeIcons.hourglassHalf : FontAwesomeIcons.bolt),
        label: w.sent ? 'Sending' : (w.full ? 'Antre' : 'Jual'),
        onPressed: w.sent ? null : w.onSell,
      ),
      if (w.full && !w.sent) ...[
        const SizedBox(width: 8),
        GlowButton(
          kind: BtnKind.dark,
          height: 40,
          radius: 13,
          icon: FontAwesomeIcons.forward,
          label: 'Skip',
          onPressed: w.onSkip,
        ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, it = w.item;
    final rc = rarityColor(it.rarity);

    Widget card = SpinBorder(
      active: _pressed && !w.selMode,
      color: rc,
      radius: 20,
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemIcon(url: w.iconUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: ItemName(it)),
                          if (w.isBooth) ...[
                            const SizedBox(width: 8),
                            PriceText(it.price),
                          ],
                        ],
                      ),
                      if (it.size == 'big')
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              color: const Color(0x1AFFFFFF),
                              border: Border.all(color: const Color(0x33FFFFFF)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(FontAwesomeIcons.rulerCombined, size: 10),
                                SizedBox(width: 6),
                                Text('Big',
                                    style: TextStyle(fontSize: 11.2, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      _footer(it),
                    ],
                  ),
                ),
              ],
            ),
            if (!w.selMode) ...[
              const SizedBox(height: 10),
              _actions(),
            ],
          ],
        ),
      ),
    );

    if (w.selected) {
      card = Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: card,
      );
    }

    return Reveal(
      index: w.index,
      child: GlassDim(
      opacity: w.dimmed ? 0.35 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Listener(
            onPointerDown: (_) => setState(() => _pressed = true),
            onPointerUp: (_) => setState(() => _pressed = false),
            onPointerCancel: (_) => setState(() => _pressed = false),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: w.selMode ? w.onTapSelect : null,
              child: card,
            ),
          ),
          if (w.selMode)
            Positioned(
              top: -7,
              left: -7,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: w.selected ? Colors.white : const Color(0xFF18181B),
                  border: Border.all(
                      color: w.selected ? Colors.white : const Color(0x44FFFFFF), width: 2),
                  boxShadow: w.selected
                      ? const [BoxShadow(color: Color(0x88FFFFFF), blurRadius: 14)]
                      : null,
                ),
                child: Icon(FontAwesomeIcons.check,
                    size: 11, color: w.selected ? Colors.black : Colors.transparent),
              ),
            ),
        ],
      ),
    ));
  }
}
