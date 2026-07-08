import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/auth/providers/auth_provider.dart';
import 'package:loyalty_app/customer/points/screens/points_history_screen.dart';
import 'package:loyalty_app/customer/home/data/home_api_service.dart';
import 'package:loyalty_app/customer/profile/data/profile_api_service.dart';
import 'package:loyalty_app/customer/points/data/points_api_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import 'main_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _adController = PageController(viewportFraction: 0.82);
  int _adIndex = 0;

  int _totalPoints = 0;
  List<int> _weeklyPts = List.filled(7, 0);
  List<TransactionModel> _recentTxs = [];

  // Track which user's data is currently loaded to avoid redundant fetches.
  String? _loadedUserId;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Defer first load until the widget tree is fully built so that
    // ref.read is safe to call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null && mounted) {
        _loadedUserId = user.id;
        _fetchHomeData(user.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch when the authenticated user changes (e.g. after a login
    // without a full navigator replacement).
    final user = ref.read(currentUserProvider);
    if (user != null && user.id != _loadedUserId && mounted) {
      _loadedUserId = user.id;
      _fetchHomeData(user.id);
    }
  }

  Future<void> _fetchHomeData(String userId) async {
    // Run all three requests concurrently; each failure is isolated so a
    // single bad endpoint doesn't blank the whole screen.
    await Future.wait([
      _loadPoints(userId),
      _loadWeekly(userId),
      _loadTransactions(userId),
    ]);
  }

Future<void> _loadPoints(String userId) async {
  try {
    final pts = await homeService.getTotalPoints(userId);
    if (mounted) setState(() => _totalPoints = pts);
  } catch (_) {}
}

  Future<void> _loadWeekly(String userId) async {
    try {
      final weekly = await homeService.getWeeklyPoints(userId);
      if (mounted) setState(() => _weeklyPts = weekly);
    } catch (_) {}
  }

  Future<void> _loadTransactions(String userId) async {
    try {
      final txs = await pointsService.getTransactions(userId);
      final today = DateTime.now();
      final todayTxs = txs
          .where((t) {
            final d = t.date.toLocal();
            return d.year == today.year &&
                   d.month == today.month &&
                   d.day == today.day;
          })
          .take(3)
          .toList();
      if (mounted) setState(() => _recentTxs = todayTxs);
    } catch (_) {}
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌤';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  String _formatPoints(int pts) {
    final str = pts.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return pts < 0 ? '-${buffer.toString()}' : buffer.toString();
  }

  void _navTo(BuildContext context, int idx) {
    final state = context.findAncestorStateOfType<MainScreenState>();
    state?.setIndex(idx);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch so the screen rebuilds when auth state changes.
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    // Trigger a fetch if the user changed while the widget was in the tree
    // but didChangeDependencies wasn't called (edge case with riverpod watch).
    if (user.id != _loadedUserId) {
      _loadedUserId = user.id;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fetchHomeData(user.id),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.bgCard,
          onRefresh: () => _fetchHomeData(user.id),
          child: SingleChildScrollView(
            // Ensure RefreshIndicator can trigger even when content is short.
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(user.name, style: AppTextStyles.h3),
                      ],
                    ),
                  ),
                  Stack(children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: AppColors.textSecondary, size: 26),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.bgDark, width: 1.5),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  InitialsAvatar(initials: user.initials, size: 42),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Advertisement Banner ──────────────────────────────────
              Column(children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Offers for you', style: AppTextStyles.h4),
                      Text('${_adIndex + 1} / ${kMockAds.length}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: PageView.builder(
                    controller: _adController,
                    itemCount: kMockAds.length,
                    onPageChanged: (i) => setState(() => _adIndex = i),
                    itemBuilder: (context, index) {
                      final ad = kMockAds[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 16 : 6,
                          right: index == kMockAds.length - 1 ? 16 : 6,
                        ),
                        child: _AdCard(ad: ad),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(kMockAds.length, (i) {
                    final active = i == _adIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Points card ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PointsHistoryScreen(userId: user.id),
                    ),
                  ),
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
                        // Left — total points hero
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.star_rounded,
                                    size: 13,
                                    color:
                                        Colors.white.withValues(alpha: 0.55)),
                                const SizedBox(width: 5),
                                Text('Total points',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.2)),
                              ]),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_formatPoints(_totalPoints),
                                      style: AppTextStyles.display
                                          .copyWith(fontSize: 42)),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: Text('pts',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.history_rounded,
                                    size: 13, color: Color(0xFFA7F3D0)),
                                const SizedBox(width: 4),
                                Text('Tap to view history',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w400)),
                              ]),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Right — weekly bar chart
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Last 7 days',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      letterSpacing: 0.3)),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 90,
                                child: _WeeklyBarChart(data: _weeklyPts),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Quick actions ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick actions', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    Row(children: [
                      _QuickAction(
                        icon: Icons.qr_code_rounded,
                        label: 'My QR Code',
                        color: AppColors.fuelColor,
                        onTap: () => _navTo(context, 2),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.bar_chart_rounded,
                        label: 'My Points',
                        color: AppColors.primary,
                        onTap: () => _navTo(context, 1),
                      ),
                      const SizedBox(width: 10),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Recent activity ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Today activities', style: AppTextStyles.h4),
                    GestureDetector(
                      onTap: () => _navTo(context, 1),
                      child: Text('See all',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_recentTxs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No transactions today.',
                      style: AppTextStyles.bodySmall),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _recentTxs
                        .map((tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TxTile(tx: tx),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<int> data;
  const _WeeklyBarChart({required this.data});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final todayIdx = DateTime.now().weekday - 1;

    return Column(children: [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final ratio =
                maxVal > 0 ? (data[i] / maxVal).clamp(0.08, 1.0) : 0.08;
            final isToday = i == todayIdx;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Tooltip(
                  message: '${data[i]} pts',
                  child: FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 5),
      Row(
        children: List.generate(7, (i) {
          final isToday = i == DateTime.now().weekday - 1;
          return Expanded(
            child: Text(
              _dayLabels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isToday
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.4),
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

// ── Ad Card Widget ────────────────────────────────────────────────────────────
class _AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  const _AdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    final gradient = [
      Color(ad['gradientStart'] as int),
      Color(ad['gradientEnd'] as int),
    ];
    final tagColor = Color(ad['tagColor'] as int);

    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left — tag + title + subtitle + hint
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(ad['tag'] as String,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tagColor)),
                  ),
                  const SizedBox(height: 8),
                  Text(ad['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3)),
                  const SizedBox(height: 3),
                  Text(ad['subtitle'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65))),
                  const Spacer(),
                  Row(children: [
                    Icon(Icons.local_offer_rounded,
                        size: 11, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text('Tap to view offer',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400)),
                  ]),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right — points badge + decorative icon
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Text(
                            ad['points'] != null
                                ? '${ad['points']} pts'
                                : '2× pts',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Widget ───────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

// ── Transaction Tile Widget ───────────────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  const _TxTile({required this.tx});

  Color _txColor() {
    if (tx.isEarned) return AppColors.success;
    if (tx.isRedeemed) return AppColors.error;
    return const Color(0xFFF97316);
  }

  IconData _txIcon() {
    if (tx.isEarned) return Icons.arrow_upward_rounded;
    if (tx.isRedeemed) return Icons.arrow_downward_rounded;
    return Icons.timer_off_rounded;
  }

  String _txTypeLabel() {
    if (tx.isEarned) return 'Earned';
    if (tx.isRedeemed) return 'Redeemed';
    return 'Expiring';
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: tx.isExpired
                    ? Icon(Icons.timer_off_rounded, size: 30, color: color)
                    : BusinessIcon(business: tx.business, size: 34),
              ),
            ),
            const SizedBox(height: 12),
            Text(tx.displayPoints,
                style: AppTextStyles.display.copyWith(fontSize: 38, color: color)),
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
                        color: color, fontWeight: FontWeight.w700, fontSize: 12)),
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
                _HomeTxDetailRow(icon: Icons.store_rounded, label: 'Business', value: tx.business),
                if (tx.isRedeemed) ...[
                  _HomeTxDivider(),
                  _HomeTxDetailRow(
                    icon: Icons.storefront_rounded,
                    label: 'Redeem Company',
                    value: (tx.redeemCompanyName != null && tx.redeemCompanyName!.isNotEmpty)
                        ? tx.redeemCompanyName!
                        : tx.business,
                  ),
                ],
                _HomeTxDivider(),
                _HomeTxDetailRow(
                    icon: Icons.swap_horiz_rounded, label: 'Transaction Type',
                    value: _txTypeLabel(), valueColor: color),
                _HomeTxDivider(),
                _HomeTxDetailRow(
                    icon: Icons.toll_rounded, label: 'Points',
                    value: tx.displayPoints, valueColor: color, bold: true),
                _HomeTxDivider(),
                _HomeTxDetailRow(icon: Icons.calendar_today_rounded, label: 'Date', value: _fmtDate(tx.date)),
                _HomeTxDivider(),
                _HomeTxDetailRow(icon: Icons.access_time_rounded, label: 'Time', value: _fmtTime(tx.date)),
                if (tx.billNo != null && tx.billNo!.isNotEmpty && tx.billNo != '-') ...[
                  _HomeTxDivider(),
                  _HomeTxDetailRow(icon: Icons.receipt_outlined, label: 'Bill No', value: tx.billNo!),
                ],
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  _HomeTxDivider(),
                  _HomeTxDetailRow(icon: Icons.notes_rounded, label: 'Note', value: tx.note!),
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
                    gradient: const LinearGradient(colors: AppColors.buttonGradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('Close',
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

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
            BusinessIcon(business: tx.business, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.businessFullName?.isNotEmpty == true ? tx.businessFullName! : tx.business, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(_txTypeLabel(), style: AppTextStyles.caption),
                ],
              ),
            ),
            Row(children: [
              Text(tx.displayPoints,
                  style: AppTextStyles.labelMedium.copyWith(color: _txColor())),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 14, color: AppColors.textSecondary),
            ]),
          ]),
        ),
      );
}

// ── Popup helpers (home) ──────────────────────────────────────────────────────
class _HomeTxDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final bool bold;
  const _HomeTxDetailRow({required this.icon, required this.label, required this.value, this.valueColor, this.bold = false});
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
          child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary, fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _HomeTxDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.border);
}