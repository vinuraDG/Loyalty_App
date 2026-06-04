// lib/features/employee/screens/redeem_flow_screen.dart
//
// Step 1 of the redemption flow: company tab rows only.
// Each row is a slim horizontal strip — icon | name | active pts | expired pts | selector.
// Selecting a row picks the company (uses its first active offer for OTP flow).
// OTP flow is completely unchanged.
//
// Returns true to the caller when redemption succeeds.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';
import 'otp_confirmation_screen.dart';

class RedeemFlowScreen extends StatefulWidget {
  final ScannedMember member;
  final String employeeId;
  final IEmpHomeService svc;

  const RedeemFlowScreen({
    super.key,
    required this.member,
    required this.employeeId,
    required this.svc,
  });

  @override
  State<RedeemFlowScreen> createState() => _RedeemFlowScreenState();
}

class _RedeemFlowScreenState extends State<RedeemFlowScreen> {
  List<RedeemableOffer>? _offers;

  /// The representative offer for the selected company (first active offer).
  RedeemableOffer? _selected;

  bool _loading = true;
  bool _sendingOtp = false;
  String? _error;

  // ── Grouping helpers ──────────────────────────────────────────────────────

  Map<String, List<RedeemableOffer>> get _grouped {
    final map = <String, List<RedeemableOffer>>{};
    for (final o in _offers ?? []) {
      map.putIfAbsent(o.business, () => []).add(o);
    }
    return map;
  }

  List<RedeemableOffer> _activeOffers(String business) =>
      (_grouped[business] ?? []).where((o) => !o.isExpired).toList();

  int _activeTotalPoints(String business) =>
      _activeOffers(business).fold(0, (s, o) => s + o.pointsCost);

  int _expiredTotalPoints(String business) =>
      (_grouped[business] ?? [])
          .where((o) => o.isExpired)
          .fold(0, (s, o) => s + o.pointsCost);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await widget.svc.getRedeemableOffers(widget.member.userId);
      if (mounted) setState(() { _offers = offers; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── OTP flow (completely unchanged) ──────────────────────────────────────

  Future<void> _sendOtpAndProceed() async {
    if (_selected == null || _sendingOtp) return;
    setState(() => _sendingOtp = true);
    try {
      final otp = await widget.svc.sendRedemptionOtp(
        customerId: widget.member.userId,
        offerId: _selected!.id,
      );
      if (!mounted) return;
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpConfirmationScreen(
            member: widget.member,
            offer: _selected!,
            employeeId: widget.employeeId,
            svc: widget.svc,
            devOtp: otp,
          ),
        ),
      );
      if (confirmed == true && mounted) {
        Navigator.pop(context, true);
      } else {
        if (mounted) setState(() => _sendingOtp = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _sendingOtp = false; _error = e.toString(); });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Redeem Points', style: AppTextStyles.h4),
                    Text('For ${widget.member.name}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.stars_rounded,
                      size: 14, color: Color(0xFFFFD700)),
                  const SizedBox(width: 4),
                  Text('${widget.member.currentPoints} pts',
                      style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Column labels ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
            child: Row(children: [
              const SizedBox(width: 46 + 12), // icon + gap
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 82,
                child: Text('Active',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 82,
                child: Text('Expired',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
              ),
              const SizedBox(width: 34), // selector column
            ]),
          ),

          Expanded(child: _buildBody()),

          // ── Confirm button (unchanged) ─────────────────────────────────────
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_selected != null) ...[
                  _SelectedSummary(
                    offer: _selected!,
                    customerPoints: widget.member.currentPoints,
                  ),
                  const SizedBox(height: 14),
                ],
                GradientButton(
                  label: _sendingOtp ? 'Sending OTP…' : 'Send OTP to Customer',
                  icon: Icons.sms_rounded,
                  onPressed: (_selected != null && !_sendingOtp)
                      ? _sendOtpAndProceed
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'An OTP will be sent to the customer\'s registered phone number.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GradientButton(label: 'Retry', onPressed: () {
              setState(() { _loading = true; _error = null; });
              _loadOffers();
            }),
          ]),
        ),
      );
    }

    final grouped = _grouped;
    final businesses = grouped.keys.toList();
    final hasAnyActive = businesses.any((b) => _activeOffers(b).isNotEmpty);

    if (!hasAnyActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.redeem_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text('No offers available',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text(
              'The customer needs more points to redeem any offer.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      itemCount: businesses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final business = businesses[i];
        final theme = _BusinessTheme.of(business);
        final active = _activeOffers(business);
        final activePts = _activeTotalPoints(business);
        final expiredPts = _expiredTotalPoints(business);
        final hasActive = active.isNotEmpty;
        final firstOffer = hasActive ? active.first : null;
        final isSelected = _selected?.business == business;

        return _CompanyRow(
          business: business,
          theme: theme,
          activeTotalPoints: activePts,
          expiredTotalPoints: expiredPts,
          isSelected: isSelected,
          hasActiveOffers: hasActive,
          onTap: hasActive
              ? () => setState(() {
                    _selected = isSelected ? null : firstOffer;
                  })
              : null,
        );
      },
    );
  }
}

// ── Business theme ─────────────────────────────────────────────────────────────

class _BusinessTheme {
  final Color color;
  final Color accentColor;
  final IconData icon;
  final List<Color> gradient;

  const _BusinessTheme({
    required this.color,
    required this.accentColor,
    required this.icon,
    required this.gradient,
  });

  static _BusinessTheme of(String business) {
    switch (business) {
      case 'Laundry':
        return const _BusinessTheme(
          color: Color(0xFF60A5FA),
          accentColor: Color(0xFF93C5FD),
          icon: Icons.local_laundry_service_rounded,
          gradient: [Color(0xFF1E3A5F), Color(0xFF1E40AF)],
        );
      case 'Gold Shop':
        return const _BusinessTheme(
          color: Color(0xFFFFD700),
          accentColor: Color(0xFFFDE68A),
          icon: Icons.diamond_rounded,
          gradient: [Color(0xFF3D2C00), Color(0xFF78580A)],
        );
      default: // Fuel Station
        return const _BusinessTheme(
          color: Color(0xFF34D399),
          accentColor: Color(0xFF6EE7B7),
          icon: Icons.local_gas_station_rounded,
          gradient: [Color(0xFF0F2027), Color(0xFF203A43)],
        );
    }
  }
}

// ── Company row ────────────────────────────────────────────────────────────────
//
// A single slim horizontal row:
//   [icon]  [company name]  [active pts pill]  [expired pts pill]  [●]
//
// Everything sits on one line — no stacking, no sub-rows.

class _CompanyRow extends StatelessWidget {
  final String business;
  final _BusinessTheme theme;
  final int activeTotalPoints;
  final int expiredTotalPoints;
  final bool isSelected;
  final bool hasActiveOffers;
  final VoidCallback? onTap;

  const _CompanyRow({
    required this.business,
    required this.theme,
    required this.activeTotalPoints,
    required this.expiredTotalPoints,
    required this.isSelected,
    required this.hasActiveOffers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.color.withValues(alpha: 0.08)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.color.withValues(alpha: 0.55)
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Business icon ────────────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.color.withValues(
                    alpha: isSelected ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(theme.icon,
                  color: theme.color,
                  size: 20),
            ),
            const SizedBox(width: 12),

            // ── Company name ─────────────────────────────────────────────────
            Expanded(
              child: Text(
                business,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? theme.accentColor
                      : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            // ── Active total pill ────────────────────────────────────────────
            _PtsPill(
              icon: Icons.stars_rounded,
              label: '$activeTotalPoints pts',
              color: const Color(0xFFFFD700),
              bgColor: const Color(0xFFFFD700).withValues(alpha: 0.12),
              borderColor: const Color(0xFFFFD700).withValues(alpha: 0.28),
              strikethrough: false,
              dimmed: !hasActiveOffers,
              width: 82,
            ),

            const SizedBox(width: 6),

            // ── Expired total pill ───────────────────────────────────────────
            _PtsPill(
              icon: Icons.timer_off_rounded,
              label: expiredTotalPoints > 0 ? '$expiredTotalPoints pts' : '—',
              color: AppColors.textMuted,
              bgColor: AppColors.textMuted.withValues(alpha: 0.07),
              borderColor: AppColors.textMuted.withValues(alpha: 0.15),
              strikethrough: expiredTotalPoints > 0,
              dimmed: true,
              width: 82,
            ),

            const SizedBox(width: 10),

            // ── Selection circle ─────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.color
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.color
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Points pill ────────────────────────────────────────────────────────────────

class _PtsPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final bool strikethrough;
  final bool dimmed;
  final double width;

  const _PtsPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.strikethrough,
    required this.dimmed,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                decoration: strikethrough
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: color,
                decorationThickness: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selected summary strip ─────────────────────────────────────────────────────
//
// Shows the chosen offer + points cost + remaining pts after deduction.

class _SelectedSummary extends StatelessWidget {
  final RedeemableOffer offer;
  final int customerPoints;

  const _SelectedSummary({
    required this.offer,
    required this.customerPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _BusinessTheme.of(offer.business);
    final remaining = customerPoints - offer.pointsCost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: theme.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(theme.icon, color: theme.color, size: 16),
        ),
        const SizedBox(width: 10),

        // Business name + offer title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.business,
                style: AppTextStyles.caption.copyWith(
                    color: theme.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 1),
              Text(
                offer.title,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Cost + remaining stacked
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Cost
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '−${offer.pointsCost} pts',
                style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            // Remaining
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                remaining >= 0
                    ? Icons.account_balance_wallet_rounded
                    : Icons.warning_amber_rounded,
                size: 11,
                color: remaining >= 0
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
              const SizedBox(width: 3),
              Text(
                '$remaining pts left',
                style: AppTextStyles.caption.copyWith(
                  color: remaining >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ],
        ),
      ]),
    );
  }
}