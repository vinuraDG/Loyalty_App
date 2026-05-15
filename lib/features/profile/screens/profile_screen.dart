import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/features/profile/screens/edit_profile_screen.dart';
import 'package:loyalty_app/features/qr/screens/qr_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [

            // ── Header ────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Text('My Profile', style: AppTextStyles.h3),
                Spacer(),
              ]),
            ),
            const SizedBox(height: 20),

            // ── User card ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  InitialsAvatar(initials: user.initials, size: 64),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name, style: AppTextStyles.h4),
                    const SizedBox(height: 3),
                    Text(user.email, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(user.phone, style: AppTextStyles.caption),
                    const SizedBox(height: 8),
                    TierBadge(tier: user.loyaltyTier),
                  ])),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // ── Stats row ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _StatCard(label: 'Total Points', value: '${user.totalPoints}',
                  color: AppColors.primary, icon: Icons.stars_rounded),
                const SizedBox(width: 10),
                _StatCard(label: 'Next Tier', value: '${user.pointsToNextTier} pts',
                  color: AppColors.accentGold, icon: Icons.military_tech_rounded),
                const SizedBox(width: 10),
                _StatCard(label: 'Tier Level', value: user.loyaltyTier,
                  color: AppColors.fuelColor, icon: Icons.emoji_events_rounded),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Tier progress ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tier Progress', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(user.loyaltyTier, style: AppTextStyles.caption),
                    if (user.loyaltyTier != 'Gold')
                      Text('${user.pointsToNextTier} pts to ${_nextTierName(user.loyaltyTier)}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.accentGold)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: user.tierProgress, minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const _TierDot(label: 'Bronze', active: true),
                    _TierDot(label: 'Silver', active: user.totalPoints >= 1000),
                    _TierDot(label: 'Gold',   active: user.totalPoints >= 5000),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── Menu section ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                _MenuSection(title: 'Account', items: [
                  _MenuItem(
                    icon: Icons.qr_code_rounded,
                    label: 'My QR Code',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QrScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    color: AppColors.accentGold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _MenuSection(title: 'Support', items: [
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    color: AppColors.golfColor,
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    color: AppColors.textSecondary,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 12),
                _MenuSection(title: '', items: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => _signOut(context, ref),  // ✅ ref in scope here
                  ),
                ]),
                const SizedBox(height: 24),
              ]),
            ),

          ]),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _nextTierName(String tier) =>
      tier == 'Bronze' ? 'Silver' : 'Gold';

  String _memberSince(DateTime d) =>
      '${_month(d.month)} ${d.year}';

  String _month(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'][m];

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showSignOutDialog(context);
    if (!confirmed) return;

    await ref.read(authProvider.notifier).signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<bool> _showSignOutDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Sign out?', style: AppTextStyles.h4,
              textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "You'll need to sign back in to access your loyalty points and rewards.",
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sign out',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          ]),
        ),
      ),
    ) ?? false;
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: AppTextStyles.labelMedium.copyWith(fontSize: 13),
        textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10),
        textAlign: TextAlign.center),
    ]),
  ));
}

class _TierDot extends StatelessWidget {
  final String label;
  final bool active;
  const _TierDot({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.border,
      ),
    ),
    const SizedBox(height: 4),
    Text(label, style: AppTextStyles.caption.copyWith(
      color: active ? AppColors.primaryLight : AppColors.textMuted,
      fontSize: 10)),
  ]);
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title.isNotEmpty) ...[
        Text(title, style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
      ],
      Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final last = e.key == items.length - 1;
            return Column(children: [
              e.value,
              if (!last) const Divider(height: 1, indent: 56,
                endIndent: 0, color: AppColors.border),
            ]);
          }).toList(),
        ),
      ),
    ],
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label,
    required this.color, this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
    title: Text(label, style: AppTextStyles.bodyMedium.copyWith(
      color: textColor ?? AppColors.textPrimary, fontSize: 14)),
    trailing: const Icon(Icons.chevron_right_rounded,
      color: AppColors.textHint, size: 20),
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
  );
}