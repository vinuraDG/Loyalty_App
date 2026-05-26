import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/mock_points_service.dart';
import '../../../models/transaction_model.dart';

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});
  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  String _filter   = 'All';
  int    _monthIdx = 0; // 0 = current month

  final _filters = ['All', 'Fuel Station', 'Laundry', 'Gold'];

  static List<Map<String, dynamic>> _buildMonths() {
    final now = DateTime.now();
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    return List.generate(6, (i) {
      // Safe arithmetic: subtract months without going below 1
      int m = now.month - i;
      int y = now.year;
      while (m <= 0) { m += 12; y -= 1; }
      final dt = DateTime(y, m, 1);
      return {
        'label': i == 0 ? 'This month' : '${names[dt.month - 1]} ${dt.year}',
        'short': i == 0 ? 'This month' : '${names[dt.month - 1].substring(0, 3)} ${dt.year}',
        'month': dt.month,
        'year' : dt.year,
      };
    });
  }

  final _months = _buildMonths();

  // Open a bottom-sheet month picker
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
                setState(() { _monthIdx = i; _filter = 'All'; });
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final svc    = MockPointsService.instance;
    final allTxs = svc.getForUser(user.id);

    // Month-filtered transactions
    final sel          = _months[_monthIdx];
    final int tMonth   = sel['month'] as int;
    final int tYear    = sel['year']  as int;
    final monthTxs     = allTxs.where((t) =>
        t.date.month == tMonth && t.date.year == tYear).toList();

    // Monthly stats
    final monthEarned   = monthTxs.where((t) =>  t.isEarned).fold<int>(0, (s, t) => s + t.points);
    final monthRedeemed = monthTxs.where((t) => !t.isEarned).fold<int>(0, (s, t) => s + t.points);
    final monthTotal    = monthEarned - monthRedeemed;

    // Today stats (always current day regardless of month picker)
    final today      = DateTime.now();
    final todayTxs   = allTxs.where((t) =>
        t.date.year == today.year &&
        t.date.month == today.month &&
        t.date.day   == today.day).toList();
    final todayEarned   = todayTxs.where((t) =>  t.isEarned).fold<int>(0, (s, t) => s + t.points);
    final todayRedeemed = todayTxs.where((t) => !t.isEarned).fold<int>(0, (s, t) => s + t.points);

    // Business filter applied on month txs
    final txs = _filter == 'All'
        ? monthTxs
        : monthTxs.where((t) => t.business == _filter).toList();

    // Monthly earned per business (only earned transactions for selected month)
    final byBiz = <String, int>{};
    for (final t in monthTxs.where((t) => t.isEarned)) {
      byBiz[t.business] = (byBiz[t.business] ?? 0) + t.points;
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [

          // ── AppBar ───────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Text('My Points', style: AppTextStyles.h3),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Balance card ─────────────────────────────────────
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Month label
                  Row(children: [
                    Icon(Icons.calendar_month_rounded,
                      size: 13, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 5),
                    Text(sel['label'] as String,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7))),
                  ]),
                  const SizedBox(height: 8),

                  // Big monthly total
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$monthTotal',
                      style: AppTextStyles.display.copyWith(fontSize: 48)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('pts',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Thin divider
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(height: 14),

                  // Today earned / redeemed
                  Row(children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Today earned',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Text(todayEarned > 0 ? '+$todayEarned' : '+0',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.success, fontSize: 22)),
                    ])),
                    Container(width: 1, height: 36,
                      color: Colors.white.withValues(alpha: 0.12)),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Today redeemed',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Text(todayRedeemed > 0 ? '-$todayRedeemed' : '-0',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.error, fontSize: 22)),
                    ])),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Per-business breakdown ────────────────────────────
              Row(children: [
                _BizCard(business: 'Fuel Station', pts: byBiz['Fuel Station'] ?? 0),
                const SizedBox(width: 8),
                _BizCard(business: 'Laundry', pts: byBiz['Laundry'] ?? 0),
                const SizedBox(width: 8),
                _BizCard(business: 'Gold', pts: byBiz['Gold'] ?? 0),
              ]),
              const SizedBox(height: 24),

              // ── Transaction History header ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction History', style: AppTextStyles.h4),
                  // Month selector button — opens bottom sheet
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
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(sel['short'] as String,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppColors.primary),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Business filter — icon tabs (single row, no overflow) ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(children: _filters.map((f) {
                  final sel = _filter == f;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? const LinearGradient(colors: AppColors.buttonGradient)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        f == 'Fuel Station' ? 'Fuel' : f,
                        style: AppTextStyles.caption.copyWith(
                          color: sel ? Colors.white : AppColors.textSecondary,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ));
                }).toList()),
              ),
              const SizedBox(height: 14),

              // ── Transaction list ──────────────────────────────────
              if (txs.isEmpty)
                Center(child: Padding(
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
                ))
              else
                ...txs.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TxCard(tx: tx),
                )),

              const SizedBox(height: 20),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _BizCard extends StatelessWidget {
  final String business;
  final int pts;
  const _BizCard({required this.business, required this.pts});

  Color get _color {
    if (business == 'Fuel Station') return AppColors.fuelColor;
    if (business == 'Laundry') return AppColors.laundryColor;
    return AppColors.accentGold;
  }

  String get _shortName {
    if (business == 'Fuel Station') return 'Fuel';
    return business;
  }

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
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
  ));
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.business, style: AppTextStyles.labelMedium),
          const SizedBox(height: 2),
          Text(
            '${tx.isEarned ? 'Earned' : 'Redeemed'} · ${_fmtRelative(tx.date)}',
            style: AppTextStyles.caption),
        ])),
        Row(children: [
          Text(tx.displayPoints,
            style: AppTextStyles.labelMedium.copyWith(
              color: tx.isEarned ? AppColors.success : AppColors.error)),
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
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Icon + amount hero
            Container(
              width: 56, height: 56,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                _Divider(),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: _fmtDate(tx.date),
                ),
                _Divider(),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: _fmtTime(tx.date),
                ),
                _Divider(),
                _DetailRow(
                  icon: Icons.toll_rounded,
                  label: 'Points',
                  value: tx.displayPoints,
                  valueColor: color,
                ),
                _Divider(),
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
                  child: Text('Close',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white)),
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
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(DateTime d) {
    final h  = d.hour;
    final m  = d.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }
}

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
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary)),
      const Spacer(),
      Text(value,
        style: AppTextStyles.labelMedium.copyWith(
          color: valueColor ?? AppColors.textPrimary,
          fontSize: 13)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: AppColors.border,
  );
}