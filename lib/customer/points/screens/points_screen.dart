import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/customer/points/data/points_api_service.dart';
import 'package:loyalty_app/customer/points/data/points_mock_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';

class PointsScreen extends ConsumerStatefulWidget {
  final IPointsService? service; // injectable for testing
  const PointsScreen({super.key, this.service});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  // 'All' | business name from AppConstants
  String _filter   = 'All';
  int    _monthIdx = 0; // 0 = current month

  IPointsService get _svc =>
      widget.service ?? PointsMockService.instance;

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

  // Called on first build and whenever an inherited dependency changes
  // (e.g. the auth provider notifies). Safer than initState because
  // ref.read is legal here, and safer than build() because it avoids
  // triggering a setState inside the build phase.
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
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 20)
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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch so the widget rebuilds when the user changes; the future itself
    // is assigned in didChangeDependencies — never inside build().
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
                // _txFuture is null only when user is not yet available.
                if (_txFuture == null ||
                    snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load transactions.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }

                final allTxs = snapshot.data ?? [];

                // ── Month slice ────────────────────────────────────────────
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
                    .where((t) => !t.isEarned)
                    .fold<int>(0, (s, t) => s + t.points);
                final monthTotal = monthEarned - monthRedeemed;

                // ── Today slice ────────────────────────────────────────────
                final today     = DateTime.now();
                final todayTxs  = allTxs.where((t) =>
                    t.date.year  == today.year  &&
                    t.date.month == today.month &&
                    t.date.day   == today.day).toList();
                final todayEarned = todayTxs
                    .where((t) => t.isEarned)
                    .fold<int>(0, (s, t) => s + t.points);
                final todayRedeemed = todayTxs
                    .where((t) => !t.isEarned)
                    .fold<int>(0, (s, t) => s + t.points);

                // ── Per-business breakdown (earned only) ───────────────────
                final byBiz = <String, int>{};
                for (final t in monthTxs.where((t) => t.isEarned)) {
                  byBiz[t.business] =
                      (byBiz[t.business] ?? 0) + t.points;
                }

                // ── Business-filtered list ──────────────────────────────────
                final txs = _filter == 'All'
                    ? monthTxs
                    : monthTxs
                        .where((t) => t.business == _filter)
                        .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Balance card ────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.cardGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.calendar_month_rounded,
                                  size: 13,
                                  color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 5),
                              Text(
                                sel['label'] as String,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.7)),
                              ),
                            ]),
                            const SizedBox(height: 8),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$monthTotal',
                                  style: AppTextStyles.display
                                      .copyWith(fontSize: 48),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'pts',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.12)),
                            const SizedBox(height: 14),

                            Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Today earned',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      todayEarned > 0
                                          ? '+$todayEarned'
                                          : '+0',
                                      style: AppTextStyles.h3.copyWith(
                                        color: AppColors.success,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 36,
                                  color: Colors.white
                                      .withValues(alpha: 0.12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Today redeemed',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      todayRedeemed > 0
                                          ? '-$todayRedeemed'
                                          : '-0',
                                      style: AppTextStyles.h3.copyWith(
                                        color: AppColors.error,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Per-business breakdown ──────────────────────────
                      Row(children: [
                        _BizCard(
                            business: kBusinessFuel,
                            pts: byBiz[kBusinessFuel] ?? 0),
                        const SizedBox(width: 8),
                        _BizCard(
                            business: kBusinessLaundry,
                            pts: byBiz[kBusinessLaundry] ?? 0),
                        const SizedBox(width: 8),
                        _BizCard(
                            business: kBusinessGold,
                            pts: byBiz[kBusinessGold] ?? 0),
                      ]),
                      const SizedBox(height: 24),

                      // ── Transaction history header ──────────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 13,
                                      color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(sel['short'] as String,
                                      style: AppTextStyles.labelSmall
                                          .copyWith(
                                              color:
                                                  AppColors.primary)),
                                  const SizedBox(width: 4),
                                  const Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Business filter tabs ───────────────────────────
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
                            // Shorten 'Fuel Station' → 'Fuel' to fit
                            final displayLabel =
                                f == kBusinessFuel ? 'Fuel' : f;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _filter = f),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: AppColors
                                                .buttonGradient)
                                        : null,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    displayLabel,
                                    style:
                                        AppTextStyles.caption.copyWith(
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

                      // ── Transaction list ───────────────────────────────
                      if (txs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(children: [
                              const Icon(Icons.receipt_long_outlined,
                                  color: AppColors.textSecondary,
                                  size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'No transactions for '
                                '${sel['label']}.',
                                style: AppTextStyles.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ]),
                          ),
                        )
                      else
                        ...txs.map((tx) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10),
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

// ── Supporting widgets ────────────────────────────────────────────────────────

class _BizCard extends StatelessWidget {
  final String business;
  final int    pts;
  const _BizCard({required this.business, required this.pts});

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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _color.withValues(alpha: 0.5)),
          ),
          child: Column(children: [
            Text(_shortName,
                style: AppTextStyles.caption.copyWith(
                    color: _color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('$pts', style: AppTextStyles.h4),
            const Text('pts', style: AppTextStyles.caption),
          ]),
        ),
      );
}

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
                    '${tx.isEarned ? 'Earned' : 'Redeemed'} · '
                    '${_fmtRelative(tx.date)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Row(children: [
              Text(
                tx.displayPoints,
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      tx.isEarned ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textSecondary),
            ]),
          ]),
        ),
      );

  void _showDetail(BuildContext context) {
    final isEarned = tx.isEarned;
    final color    = isEarned ? AppColors.success : AppColors.error;

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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Icon + amount hero
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: BusinessIcon(business: tx.business, size: 30),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              tx.displayPoints,
              style: AppTextStyles.display.copyWith(
                  fontSize: 34, color: color),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isEarned ? 'Points Earned' : 'Points Redeemed',
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // Detail rows
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _DetailRow(
                  icon: Icons.store_rounded,
                  label: 'Business',
                  value: tx.business,
                ),
                _TxDivider(),
                _DetailRow(
                  icon: Icons.receipt_outlined,
                  label: 'Bill No',
                  value: tx.billNo ?? '-',
                ),
                _TxDivider(),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: _fmtDate(tx.date),
                ),
                _TxDivider(),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: _fmtTime(tx.date),
                ),
                _TxDivider(),
                _DetailRow(
                  icon: Icons.toll_rounded,
                  label: 'Points',
                  value: tx.displayPoints,
                  valueColor: color,
                ),
                _TxDivider(),
                _DetailRow(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Type',
                  value: isEarned ? 'Earned' : 'Redeemed',
                  valueColor: color,
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Close button
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
                    style: AppTextStyles.labelMedium
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Formatters ────────────────────────────────────────────────────────────

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

// ── Detail row ─────────────────────────────────────────────────────────────────
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

// ── Thin divider used inside detail sheet ────────────────────────────────────
class _TxDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.border,
      );
}