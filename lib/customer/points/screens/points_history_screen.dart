import 'package:flutter/material.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/customer/points/data/points_api_service.dart';
import 'package:loyalty_app/customer/points/data/points_mock_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';

// ── Tab options ───────────────────────────────────────────────────────────────
enum _Tab { all, earned, redeemed, expired }

class PointsHistoryScreen extends StatefulWidget {
  final String userId;
  final IPointsService? service;

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
  _Tab _activeTab = _Tab.all;
  String? _selectedBusiness; // null = all companies

  late final AnimationController _heroAnim;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  late Future<List<TransactionModel>> _txFuture;

  IPointsService get _svc => widget.service ?? PointsMockService.instance;

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  Color _businessAccent(String business) {
    switch (business) {
      case 'Fuel Station': return const Color(0xFF60A5FA);
      case 'Laundry':      return const Color(0xFF34D399);
      case 'Gold Shop':    return const Color(0xFFFBBF24);
      default:             return AppColors.primary;
    }
  }

  IconData _businessIcon(String business) {
    switch (business) {
      case 'Fuel Station': return Icons.local_gas_station_rounded;
      case 'Laundry':      return Icons.local_laundry_service_rounded;
      case 'Gold Shop':    return Icons.diamond_rounded;
      default:             return Icons.store_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

          // ── Aggregates ────────────────────────────────────────────────────
          final totalEarned = allTxs
              .where((t) => t.isEarned)
              .fold<int>(0, (s, t) => s + t.points);
          final totalRedeemed = allTxs
              .where((t) => t.isRedeemed)
              .fold<int>(0, (s, t) => s + t.points);
          final totalExpired = allTxs
              .where((t) => t.isExpired)
              .fold<int>(0, (s, t) => s + t.points);
          final balance = totalEarned - totalRedeemed;

          // ── Per-business stats ────────────────────────────────────────────
          final businesses = allTxs.map((t) => t.business).toSet().toList()
            ..sort();
          final Map<String, _BizStats> bizStats = {};
          for (final b in businesses) {
            final bTxs = allTxs.where((t) => t.business == b);
            final earned   = bTxs.where((t) => t.isEarned)
                .fold<int>(0, (s, t) => s + t.points);
            final redeemed = bTxs.where((t) => t.isRedeemed)
                .fold<int>(0, (s, t) => s + t.points);
            final expired  = bTxs.where((t) => t.isExpired)
                .fold<int>(0, (s, t) => s + t.points);
            bizStats[b] = _BizStats(
                earned: earned, redeemed: redeemed, expired: expired);
          }

          // ── Filtered list ─────────────────────────────────────────────────
          final filtered = allTxs.where((t) {
            final bizMatch =
                _selectedBusiness == null || t.business == _selectedBusiness;
            final tabMatch = switch (_activeTab) {
              _Tab.earned   => t.isEarned,
              _Tab.redeemed => t.isRedeemed,
              _Tab.expired  => t.isExpired,
              _Tab.all      => true,
            };
            return bizMatch && tabMatch;
          }).toList();

          // ── Group by date ─────────────────────────────────────────────────
          final grouped = <String, List<TransactionModel>>{};
          for (final t in filtered) {
            grouped.putIfAbsent(_dateLabel(t.date), () => []).add(t);
          }
          final groupKeys = grouped.keys.toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  balance: balance,
                  totalEarned: totalEarned,
                  totalRedeemed: totalRedeemed,
                  totalExpired: totalExpired,
                  heroFade: _heroFade,
                  heroSlide: _heroSlide,
                  fmtFn: _fmt,
                ),
              ),

              // ── Expired warning banner (if any expired points) ────────────
              if (totalExpired > 0)
                SliverToBoxAdapter(
                  child: _ExpiredBanner(
                    totalExpired: totalExpired,
                    fmtFn: _fmt,
                    onViewExpired: () =>
                        setState(() => _activeTab = _Tab.expired),
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
                  totalExpired: totalExpired,
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
                      .where((t) => _selectedBusiness == null ||
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
                  expiredCount: allTxs
                      .where((t) =>
                          t.isExpired &&
                          (_selectedBusiness == null ||
                              t.business == _selectedBusiness))
                      .length,
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
                    if (_activeTab == _Tab.expired && filtered.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_fmt(totalExpired)} pts lost',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF97316),
                          ),
                        ),
                      ),
                    ],
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
  final int totalExpired;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final String Function(int) fmtFn;

  const _Header({
    required this.balance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.totalExpired,
    required this.heroFade,
    required this.heroSlide,
    required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
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

              FadeTransition(
                opacity: heroFade,
                child: SlideTransition(
                  position: heroSlide,
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
                            fmtFn(balance),
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

                      // 3 summary pills: Earned / Redeemed / Expired
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _SummaryPill(
                            label: 'Earned',
                            value: '+${fmtFn(totalEarned)}',
                            icon: Icons.add_circle_outline_rounded,
                            color: const Color(0xFFA7F3D0),
                          ),
                          const SizedBox(width: 10),
                          _SummaryPill(
                            label: 'Redeemed',
                            value: '-${fmtFn(totalRedeemed)}',
                            icon: Icons.remove_circle_outline_rounded,
                            color: const Color(0xFFFCA5A5),
                          ),
                          if (totalExpired > 0) ...[
                            const SizedBox(width: 10),
                            _SummaryPill(
                              label: 'Expired',
                              value: fmtFn(totalExpired),
                              icon: Icons.timer_off_rounded,
                              color: const Color(0xFFFBBF24),
                            ),
                          ],
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expired Warning Banner ────────────────────────────────────────────────────
class _ExpiredBanner extends StatelessWidget {
  final int totalExpired;
  final String Function(int) fmtFn;
  final VoidCallback onViewExpired;

  const _ExpiredBanner({
    required this.totalExpired,
    required this.fmtFn,
    required this.onViewExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: onViewExpired,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            // subtle warm amber tint
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF97316).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.timer_off_rounded,
                color: Color(0xFFF97316),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fmtFn(totalExpired)} points have expired',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Expired points cannot be redeemed.',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFF97316).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'View',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF97316).withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: const Color(0xFFF97316).withValues(alpha: 0.7),
            ),
          ]),
        ),
      ),
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
  final int totalExpired;
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
    required this.totalExpired,
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
          height: 120,
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
                expired: totalExpired,
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
                    expired: stats.expired,
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
            label: 'Earned',
            count: earnedCount,
            isActive: activeTab == _Tab.earned,
            activeColor: const Color(0xFF34D399),
            onTap: () => onTabChanged(_Tab.earned),
          ),
          _TabItem(
            label: 'Redeemed',
            count: redeemedCount,
            isActive: activeTab == _Tab.redeemed,
            activeColor: const Color(0xFFFCA5A5),
            onTap: () => onTabChanged(_Tab.redeemed),
          ),
          _TabItem(
            label: 'Expired',
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
      _Tab.earned   => (Icons.add_circle_outline_rounded,   'No earned transactions'),
      _Tab.redeemed => (Icons.remove_circle_outline_rounded,'No redeemed transactions'),
      _Tab.expired  => (Icons.timer_off_rounded,            'No expired points — great job!'),
      _Tab.all      => (Icons.receipt_long_rounded,         'No transactions found'),
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
  final int expired;
  const _BizStats(
      {required this.earned, required this.redeemed, required this.expired});
}

// ── Company Card ──────────────────────────────────────────────────────────────
class _CompanyCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final int earned;
  final int redeemed;
  final int expired;
  final bool selected;
  final String Function(int) fmtFn;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.earned,
    required this.redeemed,
    required this.expired,
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
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : AppColors.bgCard,
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
            Row(children: [
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : AppColors.textSecondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Earned',
              value: '+${fmtFn(earned)}',
              color: const Color(0xFF34D399),
            ),
            const SizedBox(height: 3),
            _StatRow(
              label: 'Redeemed',
              value: '-${fmtFn(redeemed)}',
              color: const Color(0xFFFCA5A5),
            ),
            if (expired > 0) ...[
              const SizedBox(height: 3),
              _StatRow(
                label: 'Expired',
                value: fmtFn(expired),
                color: const Color(0xFFF97316),
              ),
            ],
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
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
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

// ── Summary Pill ──────────────────────────────────────────────────────────────
class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
            Icon(icon, color: color, size: 15),
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
                    fontSize: 13,
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

// ── History Tile ──────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final TransactionModel tx;
  final Color accent;
  const _HistoryTile({required this.tx, required this.accent});

  String _timeString(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = tx.isExpired;
    final tileAccent = isExpired
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : accent;
    final time = _timeString(tx.date);

    // Expired tiles are visually dimmed
    return Opacity(
      opacity: isExpired ? 0.65 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          // Business icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tileAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
              border:
                  Border.all(color: tileAccent.withValues(alpha: 0.2), width: 1),
            ),
            child: Center(
              child: isExpired
                  ? Icon(Icons.timer_off_rounded,
                      size: 20, color: tileAccent)
                  : BusinessIcon(business: tx.business, size: 44),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.business,
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
                  _TxBadge(type: tx.type),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                ]),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tx.note!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isExpired
                          ? const Color(0xFFF97316).withValues(alpha: 0.55)
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.displayPoints,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isExpired
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
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
              Text(
                isExpired ? 'expired' : 'pts',
                style: TextStyle(
                  fontSize: 10,
                  color: isExpired
                      ? const Color(0xFFF97316).withValues(alpha: 0.55)
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ── Transaction Badge ─────────────────────────────────────────────────────────
class _TxBadge extends StatelessWidget {
  final TransactionType type;
  const _TxBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (type) {
      TransactionType.earned => (
          'Earned',
          Icons.arrow_upward_rounded,
          AppColors.success,
        ),
      TransactionType.redeemed => (
          'Redeemed',
          Icons.arrow_downward_rounded,
          AppColors.error,
        ),
      TransactionType.expired => (
          'Expired',
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