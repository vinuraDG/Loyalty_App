import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/customer/points/data/points_api_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';

class PointsScreen extends ConsumerStatefulWidget {
  final IPointsService? service;
  const PointsScreen({super.key, this.service});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  String _filter   = 'All';
  int    _monthIdx = 0;

  IPointsService get _svc =>
      widget.service ?? pointsService;

  static const _filterLabels = [
    'All',
    kBusinessFuel,
    kBusinessLaundry,
    kBusinessGold,
  ];

  static List<Map<String, dynamic>> _buildMonths() {
    final now = DateTime.now();
    const names = [
      'January', 'February', 'March',     'April',   'May',      'June',
      'July',    'August',   'September', 'October', 'November', 'December',
    ];
    return List.generate(6, (i) {
      int m = now.month - i;
      int y = now.year;
      while (m <= 0) { m += 12; y -= 1; }
      final dt = DateTime(y, m);
      return {
        'label': i == 0 ? 'This month' : '${names[dt.month - 1]} ${dt.year}',
        'short': i == 0 ? 'This month' : '${names[dt.month - 1].substring(0, 3)} ${dt.year}',
        'month': dt.month,
        'year' : dt.year,
      };
    });
  }

  final _months = _buildMonths();

  Future<List<TransactionModel>>? _txFuture;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      _txFuture = _svc.getTransactions(userId);
    }
  }

  void _pickMonth(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Select Month', style: AppTextStyles.h4),
          ),
          const SizedBox(height: 8),
          ...List.generate(_months.length, (i) {
            final m   = _months[i];
            final sel = _monthIdx == i;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: sel ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                m['label'] as String,
                style: AppTextStyles.labelMedium.copyWith(
                  color: sel ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              trailing: sel
                  ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                  : null,
              onTap: () {
                setState(() {
                  _monthIdx = i;
                  _filter   = 'All';
                });
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Business card popup ───────────────────────────────────────────────────

  void _showBizDetail(
    BuildContext context, {
    required String business,
    required int totalEarned,
    required int totalRedeemed,
    required int totalExpired,
    required Color color,
  }) {
    final netPoints = totalEarned - totalRedeemed - totalExpired;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: BusinessIcon(business: business, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business == kBusinessFuel ? 'Fuel Station' : business,
                      style: AppTextStyles.h4,
                    ),
                    Text(
                      'Points breakdown',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Text(
                    '$netPoints',
                    style: AppTextStyles.display.copyWith(
                      fontSize: 44,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'available points',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  _BizDetailRow(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: AppColors.success,
                    label: 'Total earned',
                    value: '+$totalEarned pts',
                    valueColor: AppColors.success,
                  ),
                  _BizDetailDivider(),
                  _BizDetailRow(
                    icon: Icons.remove_circle_outline_rounded,
                    iconColor: AppColors.error,
                    label: 'Total redeemed',
                    value: '-$totalRedeemed pts',
                    valueColor: AppColors.error,
                  ),
                  if (totalExpired > 0) ...[
                    _BizDetailDivider(),
                    _BizDetailRow(
                      icon: Icons.timer_off_rounded,
                      iconColor: const Color(0xFFFBBF24),
                      label: 'Expire points',
                      value: '-$totalExpired pts',
                      valueColor: const Color(0xFFFBBF24),
                    ),
                  ],
                  _BizDetailDivider(),
                  _BizDetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: color,
                    label: 'Net available',
                    value: '$netPoints pts',
                    valueColor: color,
                    bold: true,
                  ),
                ]),
              ),
              if (totalExpired > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$totalExpired pts • Expiring soon',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.buttonGradient,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Close',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Text('My Points', style: AppTextStyles.h3),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<TransactionModel>>(
              future: _txFuture,
              builder: (context, snapshot) {
                if (_txFuture == null ||
                    snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              final userId = ref.read(currentUserProvider)?.id;
                              if (userId != null) {
                                setState(() {
                                  _txFuture = _svc.getTransactions(userId);
                                });
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allTxs = snapshot.data ?? [];

                // ── Total balance (all time) for header ────────────────────
                final allEarned = allTxs
                    .where((t) => t.isEarned)
                    .fold<int>(0, (s, t) => s + t.points);
                final allRedeemed = allTxs
                    .where((t) => t.isRedeemed)
                    .fold<int>(0, (s, t) => s + t.points);
                final totalBalance = allEarned - allRedeemed;

                // ── Month slice (for list only) ────────────────────────────
                final sel        = _months[_monthIdx];
                final int tMonth = sel['month'] as int;
                final int tYear  = sel['year']  as int;

                final monthTxs = allTxs
                    .where((t) =>
                        t.date.month == tMonth && t.date.year == tYear)
                    .toList();

                final monthEarned = monthTxs
                    .where((t) => t.isEarned)
                    .fold<int>(0, (s, t) => s + t.points);
                final monthRedeemed = monthTxs
                    .where((t) => t.isRedeemed)
                    .fold<int>(0, (s, t) => s + t.points);
                final monthExpired = monthTxs
                    .where((t) => t.isExpired)
                    .fold<int>(0, (s, t) => s + t.points);

                final monthBalance = monthEarned - monthRedeemed - monthExpired;

                // ── Today slice ────────────────────────────────────────────
                final today    = DateTime.now();
                final todayTxs = allTxs.where((t) =>
                    t.date.year  == today.year  &&
                    t.date.month == today.month &&
                    t.date.day   == today.day).toList();
                final todayEarned = todayTxs
                    .where((t) => t.isEarned)
                    .fold<int>(0, (s, t) => s + t.points);
                final todayRedeemed = todayTxs
                    .where((t) => t.isRedeemed)
                    .fold<int>(0, (s, t) => s + t.points);

                // ── Per-business breakdown ─────────────────────────────────
                final byBizEarned   = <String, int>{};
                final byBizRedeemed = <String, int>{};
                final byBizExpired  = <String, int>{};

                for (final t in allTxs) {
                  if (t.isEarned) {
                    byBizEarned[t.business] =
                        (byBizEarned[t.business] ?? 0) + t.points;
                  } else if (t.isRedeemed) {
                    byBizRedeemed[t.business] =
                        (byBizRedeemed[t.business] ?? 0) + t.points;
                  } else if (t.isExpired) {
                    byBizExpired[t.business] =
                        (byBizExpired[t.business] ?? 0) + t.points;
                  }
                }

                final byBizNet = <String, int>{};
                for (final biz in [
                  kBusinessFuel,
                  kBusinessLaundry,
                  kBusinessGold,
                ]) {
                  final e = byBizEarned[biz]   ?? 0;
                  final r = byBizRedeemed[biz] ?? 0;
                  final x = byBizExpired[biz]  ?? 0;
                  byBizNet[biz] = e - r - x;
                }

                // ── Business-filtered transaction list ─────────────────────
                final txs = monthTxs
                    .where((t) => !t.isExpired)
                    .where((t) =>
                        _filter == 'All' || t.business == _filter)
                    .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Balance card (left: balance, right: stats) ────────
Container(
  width: double.infinity,
  height: 160,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: AppColors.cardGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(22),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // ── Left: month label + big balance ──────────────
      Expanded(
        flex: 5,
        child: Column(
          mainAxisSize: MainAxisSize.max,          // ← fill full height
          mainAxisAlignment: MainAxisAlignment.center, // ← center vertically
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.calendar_month_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.55)),
              const SizedBox(width: 5),
              Text(
                sel['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalBalance',
                  style: AppTextStyles.display.copyWith(fontSize: 46),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'pts',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Current balance',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.40),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),

      // Vertical divider
      Container(
        width: 1,
        height: 90,                             
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withValues(alpha: 0.15),
      ),

      // ── Right: earned / redeemed / expired stats ──────
      Expanded(
        flex: 5,
        child: Column(
          mainAxisSize: MainAxisSize.max,         
          mainAxisAlignment: MainAxisAlignment.center, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardStatRow(
              icon: Icons.arrow_upward_rounded,
              iconColor: AppColors.success,
              label: 'Earned today',
              value: todayEarned > 0 ? '+$todayEarned' : '+0',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 14),           
            _CardStatRow(
              icon: Icons.arrow_downward_rounded,
              iconColor: AppColors.error,
              label: 'Redeemed today',
              value: todayRedeemed > 0 ? '-$todayRedeemed' : '-0',
              valueColor: AppColors.error,
            ),
            if (monthExpired > 0) ...[
              const SizedBox(height: 14),
              _CardStatRow(
                icon: Icons.timer_off_rounded,
                iconColor: const Color(0xFFFBBF24),
                label: 'Expired',
                value: '$monthExpired',
                valueColor: const Color(0xFFFBBF24),
              ),
            ],
          ],
        ),
      ),
    ],
  ),
),
                      const SizedBox(height: 16),

                      // ── Per-business breakdown cards ───────────────────────
                      Row(children: [
                        _BizCard(
                          business: kBusinessFuel,
                          pts: byBizNet[kBusinessFuel] ?? 0,
                          expiredPts: byBizExpired[kBusinessFuel] ?? 0,
                          onTap: () => _showBizDetail(
                            context,
                            business: kBusinessFuel,
                            totalEarned:   byBizEarned[kBusinessFuel]   ?? 0,
                            totalRedeemed: byBizRedeemed[kBusinessFuel] ?? 0,
                            totalExpired:  byBizExpired[kBusinessFuel]  ?? 0,
                            color: AppColors.fuelColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BizCard(
                          business: kBusinessLaundry,
                          pts: byBizNet[kBusinessLaundry] ?? 0,
                          expiredPts: byBizExpired[kBusinessLaundry] ?? 0,
                          onTap: () => _showBizDetail(
                            context,
                            business: kBusinessLaundry,
                            totalEarned:   byBizEarned[kBusinessLaundry]   ?? 0,
                            totalRedeemed: byBizRedeemed[kBusinessLaundry] ?? 0,
                            totalExpired:  byBizExpired[kBusinessLaundry]  ?? 0,
                            color: AppColors.laundryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BizCard(
                          business: kBusinessGold,
                          pts: byBizNet[kBusinessGold] ?? 0,
                          expiredPts: byBizExpired[kBusinessGold] ?? 0,
                          onTap: () => _showBizDetail(
                            context,
                            business: kBusinessGold,
                            totalEarned:   byBizEarned[kBusinessGold]   ?? 0,
                            totalRedeemed: byBizRedeemed[kBusinessGold] ?? 0,
                            totalExpired:  byBizExpired[kBusinessGold]  ?? 0,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // ── Transaction history header ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Transaction History',
                              style: AppTextStyles.h4),
                          GestureDetector(
                            onTap: () => _pickMonth(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 13, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(sel['short'] as String,
                                      style: AppTextStyles.labelSmall
                                          .copyWith(color: AppColors.primary)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Business filter tabs ──────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: _filterLabels.map((f) {
                            final isSelected = _filter == f;
                            final displayLabel =
                                f == kBusinessFuel ? 'Fuel' : f;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _filter = f),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: AppColors.buttonGradient)
                                        : null,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    displayLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Transaction list ──────────────────────────────────
                      if (txs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(children: [
                              const Icon(Icons.receipt_long_outlined,
                                  color: AppColors.textSecondary, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'No transactions for ${sel['label']}.',
                                style: AppTextStyles.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ]),
                          ),
                        )
                      else
                        ...txs.map((tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TxCard(tx: tx),
                            )),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Card stat row (inside balance card right column) ──────────────────────────
class _CardStatRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;
  final Color    valueColor;

  const _CardStatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Business card ─────────────────────────────────────────────────────────────

class _BizCard extends StatelessWidget {
  final String   business;
  final int      pts;
  final int      expiredPts;
  final VoidCallback onTap;

  const _BizCard({
    required this.business,
    required this.pts,
    required this.expiredPts,
    required this.onTap,
  });

  Color get _color {
    if (business == kBusinessFuel)    return AppColors.fuelColor;
    if (business == kBusinessLaundry) return AppColors.laundryColor;
    return AppColors.accentGold;
  }

  String get _shortName {
    if (business == kBusinessFuel) return 'Fuel';
    return business;
  }

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _color.withValues(alpha: 0.5)),
            ),
            child: Column(children: [
              Text(
                _shortName,
                style: AppTextStyles.caption.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text('$pts', style: AppTextStyles.h4),
              const Text('pts', style: AppTextStyles.caption),
              if (expiredPts > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$expiredPts exp',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFFBBF24),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      );
}

// ── Biz detail popup rows ─────────────────────────────────────────────────────

class _BizDetailRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;
  final Color    valueColor;
  final bool     bold;

  const _BizDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: valueColor,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ]),
      );
}

class _BizDetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.border,
      );
}

// ── Transaction card ──────────────────────────────────────────────────────────

class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            BusinessIcon(business: tx.business, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.business, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${_txTypeLabel(tx)} · ${_fmtRelative(tx.date)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Row(children: [
              Text(
                tx.displayPoints,
                style: AppTextStyles.labelMedium.copyWith(
                  color: _txColor(tx),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textSecondary),
            ]),
          ]),
        ),
      );

  String _txTypeLabel(TransactionModel tx) {
    if (tx.isEarned)   return 'Earned';
    if (tx.isRedeemed) return 'Redeemed';
    return 'Expire';
  }

  Color _txColor(TransactionModel tx) {
    if (tx.isEarned)   return AppColors.success;
    if (tx.isRedeemed) return AppColors.error;
    return const Color(0xFFF97316);
  }

  void _showDetail(BuildContext context) {
    final color = _txColor(tx);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: tx.isExpired
                    ? Icon(Icons.timer_off_rounded, size: 26, color: color)
                    : BusinessIcon(business: tx.business, size: 30),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              tx.displayPoints,
              style: AppTextStyles.display.copyWith(fontSize: 34, color: color),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _txTypeLabel(tx),
                style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _DetailRow(icon: Icons.store_rounded,          label: 'Business', value: tx.business),
                _TxDivider(),
                _DetailRow(icon: Icons.receipt_outlined,       label: 'Bill No',  value: tx.billNo ?? '-'),
                _TxDivider(),
                _DetailRow(icon: Icons.calendar_today_rounded, label: 'Date',     value: _fmtDate(tx.date)),
                _TxDivider(),
                _DetailRow(icon: Icons.access_time_rounded,    label: 'Time',     value: _fmtTime(tx.date)),
                _TxDivider(),
                _DetailRow(icon: Icons.toll_rounded,           label: 'Points',   value: tx.displayPoints, valueColor: color),
                _TxDivider(),
                _DetailRow(icon: Icons.swap_horiz_rounded,     label: 'Type',     value: _txTypeLabel(tx), valueColor: color),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  _TxDivider(),
                  _DetailRow(icon: Icons.notes_rounded, label: 'Note', value: tx.note!),
                ],
              ]),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.buttonGradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Close',
                    style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmtRelative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 24) return 'Today';
    if (diff.inDays == 1)  return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(DateTime d) {
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final h      = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m      = d.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
              )),
        ]),
      );
}

class _TxDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.border,
      );
}