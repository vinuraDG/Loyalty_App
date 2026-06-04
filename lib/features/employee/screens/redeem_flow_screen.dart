// lib/features/employee/screens/redeem_flow_screen.dart
//
// Step 1 of the redemption flow:
//   • Company tabs scroll horizontally across the top.
//   • Tapping a tab shows that company's point summary (total active / total expired).
//   • Gold Shop only: allows redeem (OTP flow enabled).
//   • All other companies: display-only — Confirm button is hidden / disabled.
//
// OTP flow is completely unchanged.
// Returns true to the caller when redemption succeeds.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';
import 'otp_confirmation_screen.dart';

// ── Constants ──────────────────────────────────────────────────────────────────

const _kRedeemBusiness = 'Gold Shop';

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

  /// Currently selected company tab.
  String? _selectedBusiness;

  /// The representative offer for the selected company (first active offer).
  /// Only used when the selected business is Gold Shop.
  RedeemableOffer? _selectedOffer;

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

  List<RedeemableOffer> _expiredOffers(String business) =>
      (_grouped[business] ?? []).where((o) => o.isExpired).toList();

  /// Total points across ALL active offers for a business.
  int _activeTotalPoints(String business) =>
      _activeOffers(business).fold(0, (s, o) => s + o.pointsCost);

  /// Total points across ALL expired offers for a business.
  int _expiredTotalPoints(String business) =>
      _expiredOffers(business).fold(0, (s, o) => s + o.pointsCost);

  bool get _isGoldSelected => _selectedBusiness == _kRedeemBusiness;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await widget.svc.getRedeemableOffers(widget.member.userId);
      if (mounted) {
        final grouped = <String, List<RedeemableOffer>>{};
        for (final o in offers) {
          grouped.putIfAbsent(o.business, () => []).add(o);
        }
        final firstBusiness =
            grouped.keys.isNotEmpty ? grouped.keys.first : null;
        setState(() {
          _offers = offers;
          _loading = false;
          _selectedBusiness = firstBusiness;
          // Pre-select first active offer if Gold Shop is the first tab
          if (_selectedBusiness == _kRedeemBusiness) {
            final active = (grouped[_kRedeemBusiness] ?? [])
                .where((o) => !o.isExpired)
                .toList();
            _selectedOffer = active.isNotEmpty ? active.first : null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onTabTapped(String business) {
    if (_selectedBusiness == business) return;
    final active = _activeOffers(business);
    setState(() {
      _selectedBusiness = business;
      // Only auto-select an offer for Gold Shop
      _selectedOffer =
          (business == _kRedeemBusiness && active.isNotEmpty) ? active.first : null;
    });
  }

  // ── OTP flow (completely unchanged) ──────────────────────────────────────

  Future<void> _sendOtpAndProceed() async {
    if (_selectedOffer == null || _sendingOtp) return;
    setState(() => _sendingOtp = true);
    try {
      final otp = await widget.svc.sendRedemptionOtp(
        customerId: widget.member.userId,
        offerId: _selectedOffer!.id,
      );
      if (!mounted) return;
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpConfirmationScreen(
            member: widget.member,
            offer: _selectedOffer!,
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
        setState(() {
          _sendingOtp = false;
          _error = e.toString();
        });
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

          const SizedBox(height: 12),

          // ── Horizontal company tab bar ─────────────────────────────────────
          if (!_loading && _error == null) _buildCompanyTabs(),

          const SizedBox(height: 12),

          // ── Body (points summary only) ────────────────────────────────────
          Expanded(child: _buildBody()),

          // ── Confirm button — Gold Shop ONLY ────────────────────────────────
          if (!_loading && _error == null && _isGoldSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_selectedOffer != null) ...[
                  _SelectedSummary(
                    offer: _selectedOffer!,
                    customerPoints: widget.member.currentPoints,
                  ),
                  const SizedBox(height: 14),
                ],
                GradientButton(
                  label: _sendingOtp ? 'Sending OTP…' : 'Send OTP to Customer',
                  icon: Icons.sms_rounded,
                  onPressed: (_selectedOffer != null && !_sendingOtp)
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

          // ── Display-only notice for non-Gold companies ─────────────────────
          if (!_loading &&
              _error == null &&
              _selectedBusiness != null &&
              !_isGoldSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.18)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Redemption is only available for Gold Shop points.',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Horizontal company tab bar ─────────────────────────────────────────────

  Widget _buildCompanyTabs() {
    final grouped = _grouped;
    final businesses = grouped.keys.toList();
    if (businesses.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: businesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final business = businesses[i];
          final theme = _BusinessTheme.of(business);
          final isActive = _selectedBusiness == business;
          final isGold = business == _kRedeemBusiness;

          return GestureDetector(
            onTap: () => _onTabTapped(business),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.color.withValues(alpha: 0.15)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive
                      ? theme.color.withValues(alpha: 0.6)
                      : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(theme.icon,
                      size: 16,
                      color: isActive
                          ? theme.color
                          : AppColors.textMuted.withValues(alpha: 0.7)),
                  const SizedBox(width: 7),
                  Text(
                    business,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive
                          ? theme.accentColor
                          : AppColors.textMuted,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  // Gold Shop badge — "Redeem"
                  if (isGold) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Redeem',
                        style: AppTextStyles.caption.copyWith(
                          color: theme.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

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
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadOffers();
            }),
          ]),
        ),
      );
    }

    if (_selectedBusiness == null) {
      return Center(
        child: Text('No companies found.',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
      );
    }

    final business = _selectedBusiness!;
    final theme = _BusinessTheme.of(business);
    final activePts = _activeTotalPoints(business);
    final expiredPts = _expiredTotalPoints(business);

    // Only show the summary card — no offer tiles
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      children: [
        _PointsSummaryCard(
          business: business,
          theme: theme,
          activeTotalPoints: activePts,
          expiredTotalPoints: expiredPts,
        ),
      ],
    );
  }
}

// ── Points summary card ────────────────────────────────────────────────────────
//
// Shows total active and total expired points for the selected company.

class _PointsSummaryCard extends StatelessWidget {
  final String business;
  final _BusinessTheme theme;
  final int activeTotalPoints;
  final int expiredTotalPoints;

  const _PointsSummaryCard({
    required this.business,
    required this.theme,
    required this.activeTotalPoints,
    required this.expiredTotalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        // Business icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(theme.icon, color: theme.color, size: 22),
        ),
        const SizedBox(width: 12),

        // Company name
        Expanded(
          child: Text(
            business,
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textPrimary),
          ),
        ),

        // Active pts
        _StatColumn(
          label: 'Active',
          value: '$activeTotalPoints pts',
          valueColor: const Color(0xFFFFD700),
          icon: Icons.stars_rounded,
        ),

        const SizedBox(width: 16),

        // Expired pts
        _StatColumn(
          label: 'Expired',
          value: expiredTotalPoints > 0 ? '$expiredTotalPoints pts' : '—',
          valueColor: AppColors.textMuted,
          icon: Icons.timer_off_rounded,
          strikethrough: expiredTotalPoints > 0,
        ),
      ]),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final bool strikethrough;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    this.strikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: valueColor),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration:
                  strikethrough ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: valueColor,
              decorationThickness: 1.8,
            ),
          ),
        ]),
      ],
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

// ── Selected summary strip ─────────────────────────────────────────────────────
//
// Shows the chosen offer + points cost + remaining pts after deduction.
// Completely unchanged from original.

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