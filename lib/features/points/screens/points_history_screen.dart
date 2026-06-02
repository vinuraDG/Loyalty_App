import 'package:flutter/material.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/features/points/data/points_api_service.dart';
import 'package:loyalty_app/features/points/data/points_mock_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';

// ── Filter options ─────────────────────────────────────────────────────────────
enum _Filter { all, earned, redeemed }

class PointsHistoryScreen extends StatefulWidget {
  final String userId;
  final IPointsService? service; // injectable for testing; defaults to impl

  const PointsHistoryScreen({
    super.key,
    required this.userId,
    this.service,
  });

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen>
    with SingleTickerProviderStateMixin {
  _Filter _filter = _Filter.all;

  late final AnimationController _heroAnim;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  late Future<List<TransactionModel>> _txFuture;

  IPointsService get _svc =>
      widget.service ?? PointsMockService.instance;

  @override
  void initState() {
    super.initState();

    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic));

    _txFuture = _svc.getTransactions(widget.userId);
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _fmt(int pts) {
    final str = pts.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return pts < 0 ? '-${buf.toString()}' : buf.toString();
  }

  String _dateLabel(DateTime date) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    final diff  = today.difference(d).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: FutureBuilder<List<TransactionModel>>(
        future: _txFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load history.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          final allTxs = snapshot.data ?? [];

          // ── Aggregates ──────────────────────────────────────────────────────
          final totalEarned = allTxs
              .where((t) => t.isEarned)
              .fold<int>(0, (s, t) => s + t.points);
          final totalRedeemed = allTxs
              .where((t) => !t.isEarned)
              .fold<int>(0, (s, t) => s + t.points);
          final balance = totalEarned - totalRedeemed;

          // ── Filtered list ───────────────────────────────────────────────────
          final filtered = allTxs.where((t) {
            switch (_filter) {
              case _Filter.earned:   return t.isEarned;
              case _Filter.redeemed: return !t.isEarned;
              case _Filter.all:      return true;
            }
          }).toList();

          // ── Group by date label ─────────────────────────────────────────────
          final grouped = <String, List<TransactionModel>>{};
          for (final t in filtered) {
            grouped.putIfAbsent(_dateLabel(t.date), () => []).add(t);
          }
          final groupKeys = grouped.keys.toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Gradient header + hero summary ──────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.cardGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft:  Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button row
                          Row(children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Points History',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 28),

                          // Animated balance hero
                          FadeTransition(
                            opacity: _heroFade,
                            child: SlideTransition(
                              position: _heroSlide,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Balance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _fmt(balance),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 52,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'pts',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white.withValues(alpha: 0.55),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Earned / Redeemed summary pills
                                  Row(children: [
                                    _SummaryPill(
                                      label: 'Earned',
                                      value: '+${_fmt(totalEarned)}',
                                      icon: Icons.add_circle_outline_rounded,
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                    const SizedBox(width: 12),
                                    _SummaryPill(
                                      label: 'Redeemed',
                                      value: '-${_fmt(totalRedeemed)}',
                                      icon: Icons.remove_circle_outline_rounded,
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Filter chips ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Row(children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == _Filter.all,
                      onTap: () => setState(() => _filter = _Filter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Earned',
                      selected: _filter == _Filter.earned,
                      onTap: () => setState(() => _filter = _Filter.earned),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Redeemed',
                      selected: _filter == _Filter.redeemed,
                      onTap: () => setState(() => _filter = _Filter.redeemed),
                    ),
                  ]),
                ),
              ),

              // ── Transaction count ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              // ── Grouped transaction list ───────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 48,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions found',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: groupKeys.length,
                    (context, groupIdx) {
                      final key   = groupKeys[groupIdx];
                      final items = grouped[key]!;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date group header
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 8),
                              child: Text(
                                key,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.6),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            // Transactions in this group
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: List.generate(items.length, (i) {
                                  final isLast = i == items.length - 1;
                                  return Column(
                                    children: [
                                      _HistoryTile(tx: items[i]),
                                      if (!isLast)
                                        const Divider(
                                          height: 1,
                                          indent: 62,
                                          endIndent: 16,
                                          color: AppColors.border,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary Pill ───────────────────────────────────────────────────────────────
class _SummaryPill extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ── Filter Chip ────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String      label;
  final bool        selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

// ── History Tile ───────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final TransactionModel tx;
  const _HistoryTile({required this.tx});

  String _timeString(DateTime dt) {
    final h    = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m    = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.isEarned;
    final time     = _timeString(tx.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        // Business icon
        BusinessIcon(business: tx.business, size: 44),
        const SizedBox(width: 12),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.business,
                style: AppTextStyles.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isEarned ? 'Earned' : 'Redeemed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          isEarned ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ]),
            ],
          ),
        ),

        // Points amount
        Text(
          tx.displayPoints,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isEarned ? AppColors.success : AppColors.error,
          ),
        ),
      ]),
    );
  }
}