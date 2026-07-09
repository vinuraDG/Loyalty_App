import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/utils/formatters.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/customer/points/data/points_api_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/models/company_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../home/screens/main_screen.dart';

// ── Color palette cycling for dynamic companies ────────────────────────────────

const _kCompanyColors = [
  AppColors.fuelColor,
  AppColors.laundryColor,
  AppColors.accentGold,
  Color(0xFF34D399), // emerald
  Color(0xFF60A5FA), // blue
  Color(0xFFF472B6), // pink
  Color(0xFFA78BFA), // violet
  Color(0xFFFB923C), // orange
];

Color _colorForCompany(String name, int index) {
  if (name == 'Fuel' || name == kBusinessFuel)         return AppColors.fuelColor;
  if (name == 'Laundry' || name == kBusinessLaundry)   return AppColors.laundryColor;
  if (name == 'Gold House' || name == kBusinessGold)   return AppColors.accentGold;
  return _kCompanyColors[index % _kCompanyColors.length];
}

String _fmtExpiryLabel(DateTime d) {
  final l = d.toLocal();
  const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${l.day} ${mo[l.month - 1]} ${l.year}';
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class PointsScreen extends ConsumerStatefulWidget {
  final IPointsService? service;
  const PointsScreen({super.key, this.service});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  String _filter   = 'All';
  int    _monthIdx = 0;

  IPointsService get _svc => widget.service ?? pointsService;

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

  // Dynamic company list fetched from backend
  List<CompanyModel> _companies = [];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      _txFuture     = _loadAll(userId);
    }
  }

  /// Load companies + transactions together so companies are ready when
  /// we build the UI.
  Future<List<TransactionModel>> _loadAll(String userId) async {
    // Fetch companies first (cached after first call) — ignore errors,
    // transactions will still show.
    try {
      final companies = await CompaniesApiService.instance.getCompanies();
      if (mounted) setState(() { _companies = companies; });
    } catch (_) {
    }
    return _svc.getTransactions(userId);
  }

  Future<void> _refresh() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    CompaniesApiService.instance.clearCache();
    final newFuture = _loadAll(userId);
    setState(() => _txFuture = newFuture);
    await newFuture;
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

  // ── Business card popup ────────────────────────────────────────────────────

  void _showBizDetail(
    BuildContext context, {
    required String business,
    required int totalEarned,
    required int totalRedeemed,
    required int totalExpired,
    required Color color,
  }) {
    // Expiring is informational — those points are still spendable until
    // DateExpire, so they are NOT deducted from the available balance.
    final netPoints = totalEarned - totalRedeemed;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business, style: AppTextStyles.h4),
                      Text(
                        'Points breakdown',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatPoints(netPoints),
                      style: AppTextStyles.display.copyWith(
                        fontSize: 44,
                        color: color,
                      ),
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
                    label: 'Total earn',
                    value: '+${formatPoints(totalEarned)} pts',
                    valueColor: AppColors.success,
                  ),
                  _BizDetailDivider(),
                  _BizDetailRow(
                    icon: Icons.remove_circle_outline_rounded,
                    iconColor: AppColors.error,
                    label: 'Total redeem',
                    value: '-${formatPoints(totalRedeemed)} pts',
                    valueColor: AppColors.error,
                  ),
                  if (totalExpired > 0) ...[
                    _BizDetailDivider(),
                    _BizDetailRow(
                      icon: Icons.timer_off_rounded,
                      iconColor: const Color(0xFFFBBF24),
                      label: 'Expiring points',
                      value: '${formatPoints(totalExpired)} pts',
                      valueColor: const Color(0xFFFBBF24),
                    ),
                  ],
                  _BizDetailDivider(),
                  _BizDetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: color,
                    label: 'Net available',
                    value: '${formatPoints(netPoints)} pts',
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
                        '${formatPoints(totalExpired)} pts • Expiring soon',
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  final main = context.findAncestorStateOfType<MainScreenState>();
                  if (main != null) {
                    main.setIndex(0);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text('My Points', style: AppTextStyles.h3),
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
                                  _txFuture = _loadAll(userId);
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

                // ── Derive dynamic company list from transactions ───────────
                // Use companies from API if loaded; otherwise fall back to
                // distinct business names found in transactions.
                // bizNames uses DisplayName as the key — matches tx.business
                // which is also DisplayName, keeping filter logic consistent.
                final List<String> bizNames;
                final Map<String, String> fullNameOf = {
                  for (final c in _companies)
                    if (c.name.isNotEmpty) c.displayName: c.name,
                };
                if (_companies.isNotEmpty) {
                  bizNames = _companies.map((c) => c.displayName).toList();
                } else {
                  final seen = <String>{};
                  bizNames = allTxs
                      .map((t) => t.business)
                      .where((b) => b.isNotEmpty && seen.add(b))
                      .toList();
                }

                // ── Filter labels: All + per company ──────────────────────
                final filterLabels = ['All', ...bizNames];

                // Reset filter if the previously selected filter no longer
                // exists in the current company list.
                if (_filter != 'All' && !bizNames.contains(_filter)) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _filter = 'All'),
                  );
                }

                // ── Total balance (all time) ────────────────────────────────
                final allEarned = allTxs
                    .where((t) => t.isEarned)
                    .fold<int>(0, (s, t) => s + t.points);
                final allRedeemed = allTxs
                    .where((t) => t.isRedeemed)
                    .fold<int>(0, (s, t) => s + t.points);
                final totalBalance = allEarned - allRedeemed;

                // ── Month slice ────────────────────────────────────────────
                final sel        = _months[_monthIdx];
                final int tMonth = sel['month'] as int;
                final int tYear  = sel['year']  as int;

                final monthTxs = allTxs
                    .where((t) =>
                        t.date.month == tMonth && t.date.year == tYear)
                    .toList();

                final monthExpired = monthTxs
                    .where((t) => t.isExpired)
                    .fold<int>(0, (s, t) => s + t.points);

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

                // ── Per-business aggregates (all time) ────────────────────
                final byBizEarned   = <String, int>{};
                final byBizRedeemed = <String, int>{};

                for (final t in allTxs) {
                  if (t.isEarned) {
                    byBizEarned[t.business] =
                        (byBizEarned[t.business] ?? 0) + t.points;
                  } else if (t.isRedeemed) {
                    byBizRedeemed[t.business] =
                        (byBizRedeemed[t.business] ?? 0) + t.points;
                  }
                }

                final byBizNet = <String, int>{
                  for (final biz in bizNames)
                    biz: (byBizEarned[biz] ?? 0) -
                         (byBizRedeemed[biz] ?? 0),
                  // Expiring is informational only — not subtracted from net.
                };

                // ── Per-business expiring (all future expiry dates)
                final byBizExpiring = <String, int>{};
                DateTime? nearestExpiry;
                for (final t in allTxs) {
                  if (t.isEarned &&
                      t.expiryDate != null &&
                      t.expiryDate!.isAfter(DateTime.now()) &&
                      (t.expiringBalance ?? 0) > 0) {
                    byBizExpiring[t.business] =
                        (byBizExpiring[t.business] ?? 0) + t.expiringBalance!;
                    if (nearestExpiry == null ||
                        t.expiryDate!.isBefore(nearestExpiry)) {
                      nearestExpiry = t.expiryDate;
                    }
                  }
                }
                final totalExpiring = byBizExpiring.values
                    .fold<int>(0, (s, v) => s + v);

                // ── Filtered transaction list (selected month + company) ───
                final txs = monthTxs
                    .where((t) => !t.isExpired)
                    .where((t) => _filter == 'All' || t.business == _filter)
                    .toList();

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Balance card ──────────────────────────────────────
                      Container(
                        width: double.infinity,
                        height: 160,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
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
                            // Left: balance
                            Expanded(
                              flex: 5,
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            formatPoints(totalBalance),
                                            style: AppTextStyles.display
                                                .copyWith(fontSize: 46),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'pts',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
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

                            // Right: today stats
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
                                    label: 'Earn today',
                                    value: todayEarned > 0
                                        ? '+$todayEarned'
                                        : '+0',
                                    valueColor: AppColors.success,
                                  ),
                                  const SizedBox(height: 14),
                                  _CardStatRow(
                                    icon: Icons.arrow_downward_rounded,
                                    iconColor: AppColors.error,
                                    label: 'Redeem today',
                                    value: todayRedeemed > 0
                                        ? '-$todayRedeemed'
                                        : '-0',
                                    valueColor: AppColors.error,
                                  ),
                                  const SizedBox(height: 14),
                                  _CardStatRow(
                                    icon: Icons.timer_off_rounded,
                                    iconColor: totalExpiring > 0
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white38,
                                    label: nearestExpiry != null
                                        ? _fmtExpiryLabel(nearestExpiry!)
                                        : 'Expiring',
                                    value: formatPoints(totalExpiring),
                                    valueColor: totalExpiring > 0
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white38,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Per-business breakdown cards (dynamic) ────────────
                      if (bizNames.isNotEmpty)
                        _BizCardsRow(
                          bizNames: bizNames,
                          fullNameOf: fullNameOf,
                          byBizNet: byBizNet,
                          byBizEarned: byBizEarned,
                          byBizRedeemed: byBizRedeemed,
                          byBizExpired: byBizExpiring,
                          onTap: (biz, idx) => _showBizDetail(
                            context,
                            business: fullNameOf[biz] ?? biz,
                            totalEarned:   byBizEarned[biz]   ?? 0,
                            totalRedeemed: byBizRedeemed[biz] ?? 0,
                            totalExpired:  byBizExpiring[biz] ?? 0,
                            color: _colorForCompany(biz, idx),
                          ),
                        ),
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
                                      size: 13,
                                      color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(sel['short'] as String,
                                      style: AppTextStyles.labelSmall
                                          .copyWith(color: AppColors.primary)),
                                  const SizedBox(width: 4),
                                  const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Business filter tabs (equal-width) ───────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: filterLabels.map((f) {
                            final isSelected = _filter == f;
                            final displayLabel = _shortLabel(f);
                            return Expanded(
                              child: _FilterChip(
                                label: displayLabel,
                                isSelected: isSelected,
                                onTap: () => setState(() => _filter = f),
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
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  /// Full label for filter tab — no hard truncation; the chip's Text
  /// widget handles overflow with ellipsis if the name doesn't fit.
  static String _shortLabel(String name) {
    if (name == 'All') return 'All';
    if (name == kBusinessFuel) return 'Fuel';
    return name;
  }
}

// ── Dynamic biz cards row ─────────────────────────────────────────────────────

class _BizCardsRow extends StatelessWidget {
  final List<String>       bizNames;
  final Map<String, String> fullNameOf;
  final Map<String, int>   byBizNet;
  final Map<String, int>   byBizEarned;
  final Map<String, int>   byBizRedeemed;
  final Map<String, int>   byBizExpired;
  final void Function(String biz, int idx) onTap;

  const _BizCardsRow({
    required this.bizNames,
    required this.fullNameOf,
    required this.byBizNet,
    required this.byBizEarned,
    required this.byBizRedeemed,
    required this.byBizExpired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1–3 companies: single row (original layout)
    if (bizNames.length <= 3) {
      // IntrinsicHeight + stretch makes every card match the tallest one,
      // so a 2-line wrapped name (e.g. "Sunshine Laundry") doesn't leave
      // that card taller than its 1-line neighbors.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(bizNames.length, (i) {
            final biz = bizNames[i];
            return [
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _BizCard(
                  business: biz,
                  fullName: fullNameOf[biz],
                  pts: byBizNet[biz] ?? 0,
                  expiredPts: byBizExpired[biz] ?? 0,
                  color: _colorForCompany(biz, i),
                  onTap: () => onTap(biz, i),
                ),
              ),
            ];
          }).expand((w) => w).toList(),
        ),
      );
    }

    // 4+ companies: horizontally scrollable row
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bizNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final biz = bizNames[i];
          return SizedBox(
            width: 100,
            child: _BizCard(
              business: biz,
              fullName: fullNameOf[biz],
              pts: byBizNet[biz] ?? 0,
              expiredPts: byBizExpired[biz] ?? 0,
              color: _colorForCompany(biz, i),
              onTap: () => onTap(biz, i),
            ),
          );
        },
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: AppColors.buttonGradient)
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ),
      );
}

// ── Card stat row ─────────────────────────────────────────────────────────────

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
  final String       business;
  final String?      fullName;
  final int          pts;
  final int          expiredPts;
  final Color        color;
  final VoidCallback onTap;

  const _BizCard({
    required this.business,
    this.fullName,
    required this.pts,
    required this.expiredPts,
    required this.color,
    required this.onTap,
  });

  String get _label => business;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(children: [
            Text(
              _label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(formatPoints(pts), style: AppTextStyles.h4),
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
                  '-${formatPoints(expiredPts)} exp',
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
      );
}

// ── Biz detail rows ───────────────────────────────────────────────────────────

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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: valueColor,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _txTypeLabel(TransactionModel t) {
    if (t.isEarned)   return 'Earn';
    if (t.isRedeemed) return 'Redeem';
    return 'Expiring';
  }

  Color _txColor(TransactionModel t) {
    if (t.isEarned)   return AppColors.success;
    if (t.isRedeemed) return AppColors.error;
    return const Color(0xFFF97316);
  }

  IconData _txIcon(TransactionModel t) {
    if (t.isEarned)   return Icons.arrow_upward_rounded;
    if (t.isRedeemed) return Icons.arrow_downward_rounded;
    return Icons.timer_off_rounded;
  }

  String _fmtDate(DateTime d) {
    final local = d.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  String _fmtTime(DateTime d) {
    final local  = d.toLocal();
    final hour   = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h      = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$minute $period';
  }

  String _fmtDateAndTime(DateTime d) {
    final local  = d.toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour   = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h      = hour % 12 == 0 ? 12 : hour % 12;
    return '${local.day} ${months[local.month - 1]} ${local.year}  ·  $h:$minute $period';
  }

  // ── Card ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _txColor(tx);
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          // ── Icon avatar ─────────────────────────────────────────────────
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: BusinessIcon(business: tx.business, size: 28),
            ),
          ),
          const SizedBox(width: 12),

          // ── Company + badge + time ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.isRedeemed
      ? (tx.redeemCompanyFullName?.isNotEmpty == true
          ? tx.redeemCompanyFullName!
          : tx.redeemCompanyName ?? tx.business)
      : (tx.businessFullName?.isNotEmpty == true
          ? tx.businessFullName!
          : tx.business),
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(children: [
                  // Colored type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_txIcon(tx), size: 10, color: color),
                        const SizedBox(width: 3),
                        Text(
                          _txTypeLabel(tx),
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date · Time
                  Text(
                    _fmtDateAndTime(tx.date),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // ── Points + chevron ─────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.displayPoints,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'pts',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ── Detail bottom sheet ──────────────────────────────────────────────────

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Icon + points + badge ────────────────────────────────────
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: tx.isExpired
                    ? Icon(Icons.timer_off_rounded, size: 30, color: color)
                    : BusinessIcon(business: tx.business, size: 34),
              ),
            ),
            const SizedBox(height: 12),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tx.displayPoints,
                style: AppTextStyles.display.copyWith(fontSize: 38, color: color),
              ),
            ),
            const SizedBox(height: 6),

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_txIcon(tx), size: 12, color: color),
                const SizedBox(width: 3),
                Text(
                  _txTypeLabel(tx),
                  style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w700, fontSize: 12,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Detail rows ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _DetailRow(
                  icon: Icons.store_rounded,
                  label: 'Earn Company',
                  value: tx.businessFullName?.isNotEmpty == true
                      ? tx.businessFullName!
                      : tx.business,
                ),
                if (tx.isRedeemed) ...[
                  _TxDivider(),
                  _DetailRow(
                    icon: Icons.storefront_rounded,
                    label: 'Redeem Company',
                    value: tx.redeemCompanyFullName?.isNotEmpty == true
                        ? tx.redeemCompanyFullName!
                        : (tx.redeemCompanyName?.isNotEmpty == true
                            ? tx.redeemCompanyName!
                            : tx.business),
                  ),
                ],
                _TxDivider(),
                _DetailRow(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transaction Type',
                  value: _txTypeLabel(tx),
                  valueColor: color,
                ),
                _TxDivider(),
                _DetailRow(
                  icon: Icons.toll_rounded,
                  label: 'Points',
                  value: tx.displayPoints,
                  valueColor: color,
                  bold: true,
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
                if (tx.billNo != null &&
                    tx.billNo!.isNotEmpty &&
                    tx.billNo != '-') ...[
                  _TxDivider(),
                  _DetailRow(
                    icon: Icons.receipt_long_rounded,
                    label: 'Document No',
                    value: tx.billNo!,
                  ),
                ],
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  _TxDivider(),
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Note',
                    value: tx.note!,
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),

            // ── Close button ─────────────────────────────────────────────
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
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     bold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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