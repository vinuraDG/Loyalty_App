import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/auth/providers/auth_provider.dart';
import 'package:loyalty_app/customer/points/screens/points_history_screen.dart';
import 'package:loyalty_app/services/mock_points_service.dart';
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

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final svc         = MockPointsService.instance;
    final txs         = svc.getForUser(user.id).take(3).toList();
    final weeklyPts   = svc.getWeeklyPoints(user.id);
    final totalPoints = user.totalPoints;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [

            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Good morning 🌤', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Text(user.name, style: AppTextStyles.h3),
                    ],
                  ),
                ),
                Stack(children: [
                  const Icon(Icons.notifications_none_rounded,
                      color: AppColors.textSecondary, size: 26),
                  Positioned(
                    top: 2, right: 2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgDark, width: 1.5),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 12),
                InitialsAvatar(initials: user.initials, size: 42),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Advertisement Banner ─────────────────────────────────
            Column(children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
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
                height: 110,
                child: PageView.builder(
                  controller: _adController,
                  itemCount: kMockAds.length,
                  onPageChanged: (i) => setState(() => _adIndex = i),
                  itemBuilder: (context, index) {
                    final ad = kMockAds[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left:  index == 0 ? 16 : 6,
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

            // ── Points card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PointsHistoryScreen(userId: user.id)),
                ),
                child: Container(
                  width: double.infinity,
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
                                  color: Colors.white.withValues(alpha: 0.55)),
                              const SizedBox(width: 5),
                              Text('Total points',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.2)),
                            ]),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_formatPoints(totalPoints),
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
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w400)),
                            ]),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right — weekly bar chart from service
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last 7 days',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    letterSpacing: 0.3)),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 90,
                              child: _WeeklyBarChart(data: weeklyPts),
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

            // ── Quick actions ───────────────────────────────────────
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

            // ── Recent activity ─────────────────────────────────────
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

            if (txs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No transactions yet.',
                    style: AppTextStyles.bodySmall),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: txs
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
    );
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad['title'] as String,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3)),
                const SizedBox(height: 2),
                Text(ad['subtitle'] as String,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65))),
              ],
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

// ── Transaction Tile Widget ───────────────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final dynamic tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) => Container(
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
                Text(tx.business, style: AppTextStyles.labelMedium),
                const SizedBox(height: 2),
                Text(tx.isEarned ? 'Earned' : 'Redeemed',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(tx.displayPoints,
              style: AppTextStyles.labelMedium.copyWith(
                  color: tx.isEarned ? AppColors.success : AppColors.error)),
        ]),
      );
}