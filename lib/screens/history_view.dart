import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/format.dart';
import '../models/item.dart';
import '../state/dash_state.dart';
import '../widgets/item_row.dart';
import '../widgets/page_title.dart';
import '../widgets/stat_card.dart';

/// Riwayat Penjualan (Sale Record).
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final st = dash;

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

  @override
  Widget build(BuildContext context) {
    final sales = st.sales;
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
                  const PageTitle(FontAwesomeIcons.clockRotateLeft, 'Sale Record'),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: StatCard(
                        icon: FontAwesomeIcons.bagShopping,
                        label: 'Sold Item',
                        value: CountUp(st.soldCount, style: statValueStyle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        icon: FontAwesomeIcons.coins,
                        label: 'Token From Selling',
                        value: CountUp(st.soldSum, style: statValueStyle),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (sales.isEmpty)
            const SliverToBoxAdapter(child: EmptyState(FontAwesomeIcons.receipt, 'None'))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final m = sales[i];
                    final it = historyItem(m, st.nameIcons);
                    return ItemRow(
                      key: ValueKey('h${m['id']}'),
                      index: i,
                      item: it,
                      iconUrl: st.icons[it.iconId],
                      price: numOf(m['price']),
                      meta: joinMeta([
                        if (it.hasWeight) metaPart(FontAwesomeIcons.weightHanging, fw(it.weight)),
                        metaPart(FontAwesomeIcons.user, strOf(m['buyer_name'])),
                        TextSpan(text: strOf(m['sold_at'])),
                      ]),
                    );
                  },
                  childCount: sales.length,
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 90 + bottom)),
        ],
      ),
    );
  }
}
