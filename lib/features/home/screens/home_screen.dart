import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/features/auth/providers/auth_provider.dart';
import 'package:loyalty_app/services/mock_points_service.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import 'main_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final svc = MockPointsService.instance;
    final txs = svc.getForUser(user.id).take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [

            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Good morning 🌤', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(user.name, style: AppTextStyles.h3),
                ])),
                Stack(children: [
                  const Icon(Icons.notifications_none_rounded,
                    color: AppColors.textSecondary, size: 26),
                  Positioned(
                    top: 2, right: 2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle,
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

            // ── Points card ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total Points', style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${user.totalPoints}',
                      style: AppTextStyles.display.copyWith(fontSize: 46)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('pts', style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.7))),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  TierBadge(tier: '${user.loyaltyTier} Member'),
                  if (user.loyaltyTier != 'Gold') ...[
                    const SizedBox(height: 14),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(user.loyaltyTier, style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.6))),
                      Text('${user.pointsToNextTier} pts to next tier',
                        style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.6))),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: user.tierProgress,
                        minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick actions ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick actions', style: AppTextStyles.h4),
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
                  _QuickAction(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Redeem',
                    color: AppColors.accent,
                    onTap: () => _navTo(context, 3),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Recent activity ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Recent activity', style: AppTextStyles.h4),
                GestureDetector(
                  onTap: () => _navTo(context, 1),
                  child: Text('See all',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            if (txs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No transactions yet.', style: AppTextStyles.bodySmall),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: txs.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TxTile(tx: tx),
                )).toList()),
              ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _navTo(BuildContext context, int idx) {
    final state = context.findAncestorStateOfType<MainScreenState>();
    state?.setIndex(idx);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
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
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.caption.copyWith(
          fontSize: 11, color: AppColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    ),
  ));
}

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
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tx.business, style: AppTextStyles.labelMedium),
        const SizedBox(height: 2),
        Text(tx.isEarned ? 'Earned' : 'Redeemed', style: AppTextStyles.caption),
      ])),
      Text(
        tx.displayPoints,
        style: AppTextStyles.labelMedium.copyWith(
          color: tx.isEarned ? AppColors.success : AppColors.error),
      ),
    ]),
  );
}