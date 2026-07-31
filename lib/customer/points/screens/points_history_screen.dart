import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/core/providers/refresh_provider.dart';
import 'package:loyalty_app/customer/points/data/points_api_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';

// ── Tab options ───────────────────────────────────────────────────────────────
enum _Tab { all, earned, redeemed, expired }

class PointsHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  final IPointsService? service;

  const PointsHistoryScreen({
    super.key,
    required this.userId,
    this.service,
  });

  @override
  ConsumerState<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends ConsumerState<PointsHistoryScreen>
    with SingleTickerProviderStateMixin {
  _Tab _activeTab = _Tab.all;
  String? _selectedBusiness; // null = all companies

  late final AnimationController _heroAnim;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  late Future<List<TransactionModel>> _txFuture;

  IPointsService get _svc => widget.service ?? pointsService;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic));

    _txFuture = _svc.getTransactions(widget.userId);
  }

  Future<void> _reload() async {
    final newFuture = _svc.getTransactions(widget.userId);
    setState(() => _txFuture = newFuture);
    await newFuture;
  }

  Future<void> _refresh() async {
    await appRefresh(ref);
    await _reload();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(local.year, local.month, local.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month]} ${local.day}, ${local.year}';
  }

  Color _businessAccent(String business) {
    switch (business) {
      case 'Fuel':
      case 'Fuel Station':
        return const Color(0xFF60A5FA);
      case 'Laundry':
        return const Color(0xFF34D399);
      case 'Gold House':
      case 'Gold Shop':
        return const Color(0xFFFBBF24);
      default:
        return AppColors.primary;
    }
  }

  IconData _businessIcon(String business) {
    switch (business) {
      case 'Fuel':
      case 'Fuel Station':
        return Icons.local_gas_station_rounded;
      case 'Laundry':
        return Icons.local_laundry_service_rounded;
      case 'Gold House':
      case 'Gold Shop':
        return Icons.diamond_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRefreshKeyProvider, (prev, next) {
      if (prev != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reload();
        });
      }
    });

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
                      onPressed: () => setState(() {
                        _txFuture = _svc.getTransactions(widget.userId);
                      }),
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

          // ── Aggregates ────────────────────────────────────────────────────
          final totalEarned = allTxs
              .where((t) => t.isEarned)
              .fold<int>(0, (s, t) => s + t.points);
          final totalRedeemed = allTxs
              .where((t) => t.isRedeemed)
              .fold<int>(0, (s, t) => s + t.points);
          final balance = totalEarned - totalRedeemed;

          // ── Per-business stats ────────────────────────────────────────────
          final businesses = allTxs.map((t) => t.business).toSet().toList()
            ..sort();
          final Map<String, _BizStats> bizStats = {};
          for (final b in businesses) {
            final bTxs = allTxs.where((t) => t.business == b);
            final earned = bTxs
                .where((t) => t.isEarned)
                .fold<int>(0, (s, t) => s + t.points);
            final redeemed = bTxs
                .where((t) => t.isRedeemed)
                .fold<int>(0, (s, t) => s + t.points);
            bizStats[b] = _BizStats(earned: earned, redeemed: redeemed);
          }

          // ── Filtered list ─────────────────────────────────────────────────
          final filtered = allTxs.where((t) {
            final bizMatch =
                _selectedBusiness == null || t.business == _selectedBusiness;
            final tabMatch = switch (_activeTab) {
              _Tab.earned => t.isEarned,
              _Tab.redeemed => t.isRedeemed,
              _Tab.expired => t.isEarned &&
                  t.expiryDate != null &&
                  t.expiryDate!.isAfter(DateTime.now()) &&
                  t.expiryDate!.isBefore(
                      DateTime.now().add(const Duration(days: 30))) &&
                  (t.expiringBalance ?? 0) > 0,
              _Tab.all => true,
            };
            return bizMatch && tabMatch;
          }).toList();

          // ── Group by date (most recent first) ─────────────────────────────
          filtered.sort((a, b) => b.date.compareTo(a.date));
          final grouped = <String, List<TransactionModel>>{};
          for (final t in filtered) {
            grouped.putIfAbsent(_dateLabel(t.date), () => []).add(t);
          }
          final groupKeys = grouped.keys.toList();

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.bgCard,
            onRefresh: _refresh,
            child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  balance: balance,
                  totalEarned: totalEarned,
                  totalRedeemed: totalRedeemed,
                  heroFade: _heroFade,
                  heroSlide: _heroSlide,
                  fmtFn: _fmt,
                ),
              ),

              // ── Business selector ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _BusinessSelector(
                  businesses: businesses,
                  bizStats: bizStats,
                  selectedBusiness: _selectedBusiness,
                  totalEarned: totalEarned,
                  totalRedeemed: totalRedeemed,
                  fmtFn: _fmt,
                  businessAccent: _businessAccent,
                  businessIcon: _businessIcon,
                  onSelect: (b) => setState(() => _selectedBusiness = b),
                ),
              ),

              // ── Tab bar ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _TabBar(
                  activeTab: _activeTab,
                  allCount: allTxs
                      .where((t) =>
                          _selectedBusiness == null ||
                          t.business == _selectedBusiness)
                      .length,
                  earnedCount: allTxs
                      .where((t) =>
                          t.isEarned &&
                          (_selectedBusiness == null ||
                              t.business == _selectedBusiness))
                      .length,
                  redeemedCount: allTxs
                      .where((t) =>
                          t.isRedeemed &&
                          (_selectedBusiness == null ||
                              t.business == _selectedBusiness))
                      .length,
                  expiredCount: allTxs.where((t) =>
                      t.isEarned &&
                      t.expiryDate != null &&
                      t.expiryDate!.isAfter(DateTime.now()) &&
                      t.expiryDate!.isBefore(
                          DateTime.now().add(const Duration(days: 30))) &&
                      (t.expiringBalance ?? 0) > 0 &&
                      (_selectedBusiness == null || t.business == _selectedBusiness)).length,
                  onTabChanged: (t) => setState(() => _activeTab = t),
                ),
              ),

              // ── Results count row ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                  child: Row(children: [
                    if (_selectedBusiness != null) ...[
                      _BusinessBadge(
                        name: _selectedBusiness!,
                        accent: _businessAccent(_selectedBusiness!),
                        icon: _businessIcon(_selectedBusiness!),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Transaction list ──────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(child: _EmptyState(tab: _activeTab))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: groupKeys.length,
                    (context, i) {
                      final key = groupKeys[i];
                      final items = grouped[key]!;
                      return _DateGroup(
                        dateLabel: key,
                        items: items,
                        businessAccent: _businessAccent,
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int balance;
  final int totalEarned;
  final int totalRedeemed;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final String Function(int) fmtFn;

  const _Header({
    required this.balance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.heroFade,
    required this.heroSlide,
    required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── App bar ───────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
              const Text(
                'Points History',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ]),
          ),
        ),

        // ── Balance card ──────────────────────────────────────────
        FadeTransition(
          opacity: heroFade,
          child: SlideTransition(
            position: heroSlide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left — balance
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.55)),
                            const SizedBox(width: 5),
                            Text(
                              'Current Balance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ]),
                          const Spacer(),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  fmtFn(balance),
                                  style: AppTextStyles.display
                                      .copyWith(fontSize: 42),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
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
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right — summary + stats
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          _MiniStatLine(
                            label: 'Earn',
                            value: '+${fmtFn(totalEarned)}',
                            color: const Color(0xFFA7F3D0),
                          ),
                          const SizedBox(height: 6),
                          _MiniStatLine(
                            label: 'Redeem',
                            value: '-${fmtFn(totalRedeemed)}',
                            color: const Color(0xFFFCA5A5),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Business Selector ─────────────────────────────────────────────────────────
class _BusinessSelector extends StatelessWidget {
  final List<String> businesses;
  final Map<String, _BizStats> bizStats;
  final String? selectedBusiness;
  final int totalEarned;
  final int totalRedeemed;
  final String Function(int) fmtFn;
  final Color Function(String) businessAccent;
  final IconData Function(String) businessIcon;
  final void Function(String?) onSelect;

  const _BusinessSelector({
    required this.businesses,
    required this.bizStats,
    required this.selectedBusiness,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.fmtFn,
    required this.businessAccent,
    required this.businessIcon,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'BY BUSINESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          // Tall enough for the label to wrap onto 2 lines (e.g. "Sunshine
          // Laundry") without clipping or squeezing the stat rows below it.
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CompanyCard(
                label: 'All',
                icon: Icons.grid_view_rounded,
                accent: AppColors.primary,
                earned: totalEarned,
                redeemed: totalRedeemed,
                selected: selectedBusiness == null,
                fmtFn: fmtFn,
                onTap: () => onSelect(null),
              ),
              const SizedBox(width: 10),
              ...businesses.map((b) {
                final stats = bizStats[b]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _CompanyCard(
                    label: b,
                    icon: businessIcon(b),
                    accent: businessAccent(b),
                    earned: stats.earned,
                    redeemed: stats.redeemed,
                    selected: selectedBusiness == b,
                    fmtFn: fmtFn,
                    onTap: () => onSelect(b),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final _Tab activeTab;
  final int allCount;
  final int earnedCount;
  final int redeemedCount;
  final int expiredCount;
  final void Function(_Tab) onTabChanged;

  const _TabBar({
    required this.activeTab,
    required this.allCount,
    required this.earnedCount,
    required this.redeemedCount,
    required this.expiredCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          _TabItem(
            label: 'All',
            count: allCount,
            isActive: activeTab == _Tab.all,
            activeColor: AppColors.primary,
            onTap: () => onTabChanged(_Tab.all),
          ),
          _TabItem(
            label: 'Earn',
            count: earnedCount,
            isActive: activeTab == _Tab.earned,
            activeColor: const Color(0xFF34D399),
            onTap: () => onTabChanged(_Tab.earned),
          ),
          _TabItem(
            label: 'Redeem',
            count: redeemedCount,
            isActive: activeTab == _Tab.redeemed,
            activeColor: const Color(0xFFFCA5A5),
            onTap: () => onTabChanged(_Tab.redeemed),
          ),
          _TabItem(
            label: 'Expiring',
            count: expiredCount,
            isActive: activeTab == _Tab.expired,
            activeColor: const Color(0xFFF97316),
            onTap: () => onTabChanged(_Tab.expired),
          ),
        ]),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? activeColor : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? activeColor
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date Group ────────────────────────────────────────────────────────────────
class _DateGroup extends StatelessWidget {
  final String dateLabel;
  final List<TransactionModel> items;
  final Color Function(String) businessAccent;

  const _DateGroup({
    required this.dateLabel,
    required this.items,
    required this.businessAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8, left: 4),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.55),
                letterSpacing: 0.3,
              ),
            ),
          ),
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
                    _HistoryTile(
                      tx: items[i],
                      accent: businessAccent(items[i].business),
                    ),
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
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final _Tab tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (tab) {
      _Tab.earned => (
          Icons.add_circle_outline_rounded,
          'No earn transactions'
        ),
      _Tab.redeemed => (
          Icons.remove_circle_outline_rounded,
          'No redeem transactions'
        ),
      _Tab.expired => (
          Icons.timer_off_rounded,
          'No expiring points'
        ),
      _Tab.all => (Icons.receipt_long_rounded, 'No transactions found'),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-business stats ────────────────────────────────────────────────────────
class _BizStats {
  final int earned;
  final int redeemed;
  const _BizStats({required this.earned, required this.redeemed});
}

// ── Company Card ──────────────────────────────────────────────────────────────
class _CompanyCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final int earned;
  final int redeemed;
  final bool selected;
  final String Function(int) fmtFn;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.earned,
    required this.redeemed,
    required this.selected,
    required this.fmtFn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        // Widened from 148 → 168 and paired with a 2-line label below so
        // full company names (e.g. "Sunshine Laundry") aren't squeezed
        // into a single-line ellipsis like "Sunshine La...".
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Earn',
              value: '+${fmtFn(earned)}',
              color: const Color(0xFF34D399),
            ),
            const SizedBox(height: 3),
            _StatRow(
              label: 'Redeem',
              value: '-${fmtFn(redeemed)}',
              color: const Color(0xFFFCA5A5),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mini Stat Line (used in header balance card) ──────────────────────────────
class _MiniStatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Business Badge (results row) ──────────────────────────────────────────────
class _BusinessBadge extends StatelessWidget {
  final String name;
  final Color accent;
  final IconData icon;
  const _BusinessBadge(
      {required this.name, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: accent),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Tile ──────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final TransactionModel tx;
  final Color accent;
  const _HistoryTile({required this.tx, required this.accent});

  String _timeString(DateTime dt) {
    final t = dt.toLocal();
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String _fmtDate(DateTime d) { d = d.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(DateTime d) {
    final local  = d.toLocal();
    final hour   = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h      = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$minute $period';
  }

  bool _isExpiringSoon() {
    if (!tx.isEarned || tx.expiryDate == null || (tx.expiringBalance ?? 0) <= 0) return false;
    final now = DateTime.now();
    return tx.expiryDate!.isAfter(now) &&
        tx.expiryDate!.isBefore(now.add(const Duration(days: 30)));
  }

  String _txTypeLabel() {
    if (tx.isRedeemed) return 'Redeem';
    if (_isExpiringSoon() || tx.isExpired) return 'Expiring';
    return 'Earn';
  }

  IconData _txIcon() {
    if (tx.isRedeemed) return Icons.arrow_downward_rounded;
    if (_isExpiringSoon() || tx.isExpired) return Icons.timer_off_rounded;
    return Icons.arrow_upward_rounded;
  }

  Color _txColor() {
    if (_isExpiringSoon() || tx.isExpired) return const Color(0xFFF97316);
    if (tx.isEarned) return AppColors.success;
    return AppColors.error;
  }

  void _showDetail(BuildContext context) {
    final color = _txColor();
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: (_isExpiringSoon() || tx.isExpired)
                    ? Icon(Icons.timer_off_rounded, size: 30, color: color)
                    : BusinessIcon(business: tx.business, size: 34),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isExpiringSoon()
                  ? '${tx.expiringBalance} pts'
                  : tx.displayPoints,
              style: AppTextStyles.display.copyWith(fontSize: 38, color: color),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_txIcon(), size: 12, color: color),
                const SizedBox(width: 5),
                Text(_txTypeLabel(),
                    style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _HistDetailRow(
                    icon: Icons.store_rounded,
                    label: 'Earn Company',
                    value: tx.businessFullName?.isNotEmpty == true
                        ? tx.businessFullName!
                        : tx.business),
                if (tx.isRedeemed) ...[
                  _HistDivider(),
                  _HistDetailRow(
                    icon: Icons.storefront_rounded,
                    label: 'Redeem Company',
                    value: tx.redeemCompanyFullName?.isNotEmpty == true
                        ? tx.redeemCompanyFullName!
                        : (tx.redeemCompanyName?.isNotEmpty == true
                            ? tx.redeemCompanyName!
                            : tx.business),
                  ),
                ],
                _HistDivider(),
                _HistDetailRow(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transaction Type',
                    value: _txTypeLabel(),
                    valueColor: color),
                _HistDivider(),
                _HistDetailRow(
                    icon: Icons.toll_rounded,
                    label: 'Points',
                    value: _isExpiringSoon()
                        ? '${tx.expiringBalance} pts'
                        : tx.displayPoints,
                    valueColor: color,
                    bold: true),
                _HistDivider(),
                _HistDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _fmtDate(tx.date)),
                _HistDivider(),
                _HistDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _fmtTime(tx.date)),
                if (_isExpiringSoon() && tx.expiryDate != null) ...[
                  _HistDivider(),
                  _HistDetailRow(
                      icon: Icons.event_busy_rounded,
                      label: 'Expires On',
                      value: _fmtDate(tx.expiryDate!),
                      valueColor: const Color(0xFFF97316)),
                ],
                if (tx.billNo != null &&
                    tx.billNo!.isNotEmpty &&
                    tx.billNo != '-') ...[
                  _HistDivider(),
                  _HistDetailRow(
                      icon: Icons.receipt_long_rounded,
                      label: 'Document No',
                      value: tx.billNo!),
                ],
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  _HistDivider(),
                  _HistDetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Note',
                      value: tx.note!),
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
                    gradient:
                        const LinearGradient(colors: AppColors.buttonGradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('Close',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = tx.isExpired;
    final isExpiringSoon = _isExpiringSoon();
    final isWarning = isExpiringSoon || isExpired;
    const warningColor = Color(0xFFF97316);
    final tileAccent = isExpired
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : isExpiringSoon
            ? warningColor
            : accent;
    final _local = tx.date.toLocal();
    final _hh = _local.hour % 12 == 0 ? 12 : _local.hour % 12;
    const _sm = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final time = '${_local.day} ${_sm[_local.month - 1]} ${_local.year}  ·  $_hh:${_local.minute.toString().padLeft(2, '0')} ${_local.hour >= 12 ? 'PM' : 'AM'}';

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Opacity(
        opacity: isExpired ? 0.65 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tileAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: tileAccent.withValues(alpha: 0.2), width: 1),
              ),
              child: Center(
                child: isWarning
                    ? Icon(Icons.timer_off_rounded, size: 20, color: tileAccent)
                    : BusinessIcon(business: tx.business, size: 44),
              ),
            ),
            const SizedBox(width: 12),
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
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isExpired
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : null,
                      decoration: isExpired
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor:
                          AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    _TxBadge(
                        type: isExpiringSoon
                            ? TransactionType.expired
                            : tx.type),
                    const SizedBox(width: 6),
                    Text(time,
                        style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ]),
                  if (tx.note != null && tx.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tx.note!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isWarning
                            ? warningColor.withValues(alpha: 0.55)
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isExpiringSoon
                      ? '${tx.expiringBalance}'
                      : tx.displayPoints,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isExpired
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
                        : isExpiringSoon
                            ? warningColor
                            : tx.isEarned
                                ? AppColors.success
                                : AppColors.error,
                    decoration: isExpired
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor:
                        AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    isWarning ? 'expiring' : 'pts',
                    style: TextStyle(
                      fontSize: 10,
                      color: isWarning
                          ? warningColor.withValues(alpha: 0.55)
                          : AppColors.textSecondary.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 12, color: AppColors.textSecondary),
                ]),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Popup helpers (points history) ────────────────────────────────────────────
//
// FIX (alignment + no-crash for long/missing values):
// - Added a fixed-width label column (`SizedBox(width: 110, ...)`) so every
//   row's value starts at the exact same x-position — this is what gives
//   the "title: value" list look in the screenshot.
// - Replaced `Flexible` + single-line `ellipsis` with `Expanded` + wrapping
//   text (`softWrap: true`, `maxLines: 3`), so long values like business
//   names wrap onto extra lines instead of being cut off with "…".
// - Falls back to '-' if value is somehow empty, instead of rendering a
//   blank cell.
class _HistDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final bool bold;
  const _HistDetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor,
      this.bold = false});

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
                value.isNotEmpty ? value : '-',
                textAlign: TextAlign.right,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}

class _HistDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.border);
}

// ── Transaction Badge ─────────────────────────────────────────────────────────
class _TxBadge extends StatelessWidget {
  final TransactionType type;
  const _TxBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (type) {
      TransactionType.earned => (
          'Earn',
          Icons.arrow_upward_rounded,
          AppColors.success,
        ),
      TransactionType.redeemed => (
          'Redeem',
          Icons.arrow_downward_rounded,
          AppColors.error,
        ),
      TransactionType.expired => (
          'Expiring',
          Icons.timer_off_rounded,
          const Color(0xFFF97316),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}