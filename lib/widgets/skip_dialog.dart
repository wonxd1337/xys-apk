import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme.dart';
import '../models/item.dart';
import 'glow_button.dart';
import 'item_widgets.dart';

/// Skip antrian: "Place Now" (turunkan 1 item booth sebagai pengganti)
/// atau "Prioritize in Queue" (maju ke depan antrian).
/// Hasil pop: {'skip':1} | {'type':'swap_sell','replace_uuid':..} | null
class SkipDialog extends StatefulWidget {
  const SkipDialog({
    super.key,
    required this.item,
    required this.price,
    required this.booth,
    required this.icons,
  });

  final Item item;
  final int price;
  final List<Item> booth;
  final Map<String, String> icons;

  @override
  State<SkipDialog> createState() => _SkipDialogState();
}

class _SkipDialogState extends State<SkipDialog> {
  bool pick = false;

  static const _note = TextStyle(color: C.muted, fontSize: 13, height: 1.35);

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final booth = [...w.booth]..sort((a, b) => a.price.compareTo(b.price));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(pick ? FontAwesomeIcons.rightLeft : FontAwesomeIcons.forward,
                size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(pick ? 'Choose Replacement' : 'Skip Queue',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.8)),
        ]),
        const SizedBox(height: 18),
        if (!pick) ...[
          ItemSummary(item: w.item, iconUrl: w.icons[w.item.iconId], price: w.price),
          const SizedBox(height: 16),
          GlowButton(
            icon: FontAwesomeIcons.bolt,
            label: 'Place Now',
            expand: true,
            onPressed: () => setState(() => pick = true),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 6, 2, 14),
            child: Text('Take one booth item down and place this item right away.',
                style: _note),
          ),
          GlowButton(
            kind: BtnKind.dark,
            icon: FontAwesomeIcons.listCheck,
            label: 'Prioritize in Queue',
            expand: true,
            onPressed: () => Navigator.of(context).pop(<String, dynamic>{'skip': 1}),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 6, 2, 0),
            child: Text(
                'Move this item to the front of the queue. It is placed when the next slot opens.',
                style: _note),
          ),
        ] else if (booth.isEmpty)
          const Text('No booth items to replace.', style: _note)
        else ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Pick the booth item to take down. It goes back to your inventory.',
                style: _note),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: booth.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final z = booth[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(<String, dynamic>{
                    'type': 'swap_sell',
                    'replace_uuid': z.uuid,
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x59000000),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: Row(children: [
                      ItemIcon(url: w.icons[z.iconId], size: 40),
                      const SizedBox(width: 10),
                      Expanded(child: ItemName(z, fontSize: 14)),
                      const SizedBox(width: 8),
                      PriceText(z.price, fontSize: 14),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        GlowButton(
          kind: BtnKind.dark,
          label: 'Batal',
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
