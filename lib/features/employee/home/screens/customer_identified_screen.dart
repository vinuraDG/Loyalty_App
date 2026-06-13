// lib/features/employee/screens/customer_identified_screen.dart
//
// Shown after the QR scanner successfully identifies a member.
// Displays customer info + two primary actions:
//   • Earn  → opens the fuel-sale entry sheet (existing flow)
//   • Redeem → navigates to RedeemFlowScreen
//
// Navigation contract
//   Push: Navigator.push(context, MaterialPageRoute(builder: (_) =>
//           CustomerIdentifiedScreen(member: member, employee: emp, svc: svc)))
//   After earn / redeem completes, this screen pops itself with a result
//   so the home page can refresh its scan list.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';
import 'fuel_entry_sheet.dart';
import 'redeem_flow_screen.dart';

class CustomerIdentifiedScreen extends StatefulWidget {
  final ScannedMember member;
  final String employeeId;
  final IEmpHomeService svc;

  const CustomerIdentifiedScreen({
    super.key,
    required this.member,
    required this.employeeId,
    required this.svc,
  });

  @override
  State<CustomerIdentifiedScreen> createState() =>
      _CustomerIdentifiedScreenState();
}

class _CustomerIdentifiedScreenState extends State<CustomerIdentifiedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Keep a live copy so points update after earn/redeem.
  late ScannedMember _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  // ── Refresh member after a transaction ───────────────────────────────────

  Future<void> _refreshMember() async {
    try {
      final updated = await widget.svc.getMemberByQr(_member.userId);
      if (mounted) setState(() => _member = updated);
    } catch (_) {}
  }

  // ── Earn flow ─────────────────────────────────────────────────────────────

  Future<void> _startEarnFlow() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => FuelEntrySheet(
        member: _member,
        employeeId: widget.employeeId,
        svc: widget.svc,
      ),
    );
    if (result == true) {
      await _refreshMember();
      if (mounted) {
        _showSuccessSnack('Points awarded to ${_member.name}!');
      }
    }
  }

  // ── Redeem flow ───────────────────────────────────────────────────────────

  Future<void> _startRedeemFlow() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RedeemFlowScreen(
          member: _member,
          employeeId: widget.employeeId,
          svc: widget.svc,
        ),
      ),
    );
    if (result == true) {
      await _refreshMember();
      if (mounted) {
        _showSuccessSnack('Redemption confirmed for ${_member.name}!');
      }
    }
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.greenAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ]),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final initials =
        _member.name.split(' ').map((w) => w[0]).take(2).join();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(children: [
              // ── App bar ──────────────────────────────────────────────
              _AppBar(onClose: () => Navigator.pop(context)),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Identification badge ─────────────────────────
                      _IdentificationBanner(member: _member, initials: initials),
                      const SizedBox(height: 24),

                      // ── Points hero ──────────────────────────────────
                      _PointsHero(member: _member),
                      const SizedBox(height: 32),

                      // ── Action label ─────────────────────────────────
                      const Text('What would you like to do?',
                          style: AppTextStyles.h4),
                      const SizedBox(height: 14),

                      // ── Earn card ────────────────────────────────────
                      _ActionCard(
                        icon: Icons.local_gas_station_rounded,
                        iconColor: AppColors.primaryLight,
                        iconBg:
                            AppColors.primaryLight.withValues(alpha: 0.12),
                        title: 'Earn Points',
                        subtitle:
                            'Record a fuel sale and award loyalty points',
                        badge: '+pts',
                        badgeColor: Colors.greenAccent,
                        badgeBg: Colors.green.withValues(alpha: 0.12),
                        onTap: _startEarnFlow,
                      ),
                      const SizedBox(height: 12),

                      // ── Redeem card ──────────────────────────────────
                      _ActionCard(
                        icon: Icons.redeem_rounded,
                        iconColor: const Color(0xFFFFB347),
                        iconBg: const Color(0xFFFFB347).withValues(alpha: 0.12),
                        title: 'Redeem Points',
                        subtitle:
                            'Apply an offer using the customer\'s points',
                        badge: '−pts',
                        badgeColor: const Color(0xFFFFB347),
                        badgeBg:
                            const Color(0xFFFFB347).withValues(alpha: 0.12),
                        onTap: _member.currentPoints > 0
                            ? _startRedeemFlow
                            : null,
                        disabled: _member.currentPoints == 0,
                        disabledHint: 'No points to redeem',
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final VoidCallback onClose;
  const _AppBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 4),
        const Text('Customer Identified', style: AppTextStyles.h4),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_rounded,
                color: Colors.greenAccent, size: 13),
            const SizedBox(width: 4),
            Text('Verified',
                style: AppTextStyles.caption.copyWith(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _IdentificationBanner extends StatelessWidget {
  final ScannedMember member;
  final String initials;
  const _IdentificationBanner(
      {required this.member, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        InitialsAvatar(initials: initials, size: 52),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name, style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text('ID: #${member.memberId}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 4),
              if (member.phone.isNotEmpty)
                Text(member.phone,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        // TierBadge removed
      ]),
    );
  }
}

/// Full-width hero card that shows the member's point balance prominently.
class _PointsHero extends StatelessWidget {
  final ScannedMember member;
  const _PointsHero({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.bgCard,
            const Color(0xFFFFD700).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.stars_rounded,
                color: Color(0xFFFFD700), size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Points',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                member.currentPoints.toString(),
                style: AppTextStyles.h4.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (member.currentPoints == 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'No points',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted),
              ),
            )
         
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final VoidCallback? onTap;
  final bool disabled;
  final String? disabledHint;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.onTap,
    this.disabled = false,
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: disabled
                  ? AppColors.border
                  : iconColor.withValues(alpha: 0.25),
              width: disabled ? 1 : 1.5,
            ),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 3),
                  Text(
                    disabled && disabledHint != null
                        ? disabledHint!
                        : subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: badgeBg, borderRadius: BorderRadius.circular(20)),
              child: Text(badge,
                  style: AppTextStyles.caption.copyWith(
                      color: badgeColor, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ]),
        ),
      ),
    );
  }
}