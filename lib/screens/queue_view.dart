import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/item.dart';
import '../state/dash_state.dart';
import '../widgets/confirm_box.dart';
import '../widgets/glow_button.dart';
import '../widgets/item_row.dart';
import '../widgets/item_widgets.dart';
import '../widgets/page_title.dart';
import '../widgets/toast.dart';

/// Antrian Jual: item menunggu slot booth kosong.
class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  final st = dash;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    st.addListener(_u);
  }

  @override
  void dispose() {
    st.removeListener(_u);
    super.dispose();
  }

  void _u() {
    if (mounted) setState(() {});
  }

  Future<void> _run(String type, Map<String, dynamic> q) async {
    final r = await st.run({'type': type, 'queue_id': '${q['id']}'});
    if (!mounted) return;
    showToast(context, r.message,
        icon: r.ok ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.triangleExclamation);
  }

  Future<void> _clear() async {
    if (_busy || st.queue.isEmpty) return;
    _busy = true;
    final items = st.queue.map(Item.new).toList();
    final ok = await confirmBox(
      context,
      title: 'Hapus semua antrian?',
      icon: FontAwesomeIcons.trashCan,
      danger: true,
      okIcon: FontAwesomeIcons.trashCan,
      okLabel: 'Ya, Hapus Semua',
      body: ManySummary(
        items: items,
        headline: '${items.length} item dalam antrian',
        note: 'Semua antrian jual dibatalkan. Item tetap ada di inventaris.',
      ),
    );
    _busy = false;
    if (!ok) return;
    final r = await st.run({'type': 'clear_queue'});
    if (!mounted) return;
    showToast(context, r.message,
        icon: r.ok ? FontAwesomeIcons.trashCan : FontAwesomeIcons.triangleExclamation);
  }

  @override
  Widget build(BuildContext context) {
    final q = st.queue;
    final full = st.full;
    final bottom = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
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
                  const PageTitle(FontAwesomeIcons.listCheck, 'Queue Sell'),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text('Item menunggu slot booth kosong.',
                        style: TextStyle(color: C.muted, fontSize: 12.8)),
                  ),
                  if (q.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: GlowButton(
                        kind: BtnKind.trash,
                        icon: FontAwesomeIcons.trashCan,
                        label: 'Hapus Semua Antrian',
                        onPressed: _clear,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (q.isEmpty)
            const SliverToBoxAdapter(child: EmptyState(FontAwesomeIcons.inbox, 'Antrian kosong.'))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final m = q[i];
                    final it = Item(m);
                    return ItemRow(
                      key: ValueKey('q${m['id']}'),
                      index: i,
                      item: it,
                      iconUrl: st.icons[it.iconId],
                      price: it.price,
                      meta: joinMeta([
                        TextSpan(text: '#${i + 1}'),
                        if (it.hasWeight) metaPart(FontAwesomeIcons.weightHanging, fw(it.weight)),
                        metaPart(FontAwesomeIcons.clock, strOf(m['created_at'])),
                      ]),
                      actions: [
                        if (full && i > 0)
                          GlowButton(
                            kind: BtnKind.dark,
                            icon: FontAwesomeIcons.forward,
                            height: 38,
                            width: 38,
                            radius: 12,
                            padding: EdgeInsets.zero,
                            onPressed: () => _run('prioritize', m),
                          ),
                        GlowButton(
                          kind: BtnKind.dark,
                          icon: FontAwesomeIcons.xmark,
                          height: 38,
                          width: 38,
                          radius: 12,
                          padding: EdgeInsets.zero,
                          onPressed: () => _run('cancel', m),
                        ),
                      ],
                    );
                  },
                  childCount: q.length,
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 90 + bottom)),
        ],
      ),
    );
  }
}
