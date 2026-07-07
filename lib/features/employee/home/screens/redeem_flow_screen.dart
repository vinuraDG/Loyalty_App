// lib/features/employee/screens/redeem_flow_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';
import 'otp_confirmation_screen.dart';
import '../../../../models/user_model.dart';

// No longer used — panel visibility is driven by _selectedOffer != null

class RedeemFlowScreen extends StatefulWidget {
  final ScannedMember member;
  final String employeeId;
  final IEmpHomeService svc;
  final UserModel employee;

  const RedeemFlowScreen({
    super.key,
    required this.member,
    required this.employeeId,
    required this.svc,
    required this.employee,
  });

  @override
  State<RedeemFlowScreen> createState() => _RedeemFlowScreenState();
}

class _RedeemFlowScreenState extends State<RedeemFlowScreen> {
  List<RedeemableOffer>? _offers;
  String? _selectedBusiness;
  RedeemableOffer? _selectedOffer;
  bool _loading = true;
  bool _sendingOtp = false;
  String? _error;

  final _pointsController = TextEditingController();
  int? _pointsToRedeem;
  String? _pointsError;

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  void _resetPointsInput() {
    _pointsController.clear();
    _pointsToRedeem = null;
    _pointsError = null;
  }

  void _onPointsChanged(String raw) {
    final parsed = int.tryParse(raw.trim());
    final available = widget.member.currentPoints;
    setState(() {
      if (raw.trim().isEmpty) {
        _pointsToRedeem = null;
        _pointsError = null;
      } else if (parsed == null || parsed <= 0) {
        _pointsToRedeem = null;
        _pointsError = 'Enter a valid number of points.';
      } else if (parsed > available) {
        _pointsToRedeem = null;
        _pointsError = 'Exceeds available $available pts.';
      } else {
        _pointsToRedeem = parsed;
        _pointsError = null;
      }
    });
  }

  // ── Grouping helpers ──────────────────────────────────────────────────────

  Map<String, List<RedeemableOffer>> get _grouped {
    final map = <String, List<RedeemableOffer>>{};
    for (final o in _offers ?? []) {
      map.putIfAbsent(o.business, () => []).add(o);
    }
    return map;
  }

  /// Only active (non-expired) offers
  List<RedeemableOffer> _activeOffers(String business) =>
      (_grouped[business] ?? []).where((o) => !o.isExpired).toList();

  List<RedeemableOffer> _expiredOffers(String business) =>
      (_grouped[business] ?? []).where((o) => o.isExpired).toList();

  int _activeTotalPoints(String business) =>
      _activeOffers(business).fold(0, (s, o) => s + o.pointsCost);

  int _expiredTotalPoints(String business) =>
      _expiredOffers(business).fold(0, (s, o) => s + o.pointsCost);

  bool get _isGoldSelected => _selectedOffer != null;

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
        // Auto-select the first available offer from whatever the backend returns
        final firstActive = offers.where((o) => !o.isExpired).toList();
        setState(() {
          _offers = offers;
          _loading = false;
          _selectedBusiness =
              firstActive.isNotEmpty ? firstActive.first.business : null;
          _selectedOffer =
              firstActive.isNotEmpty ? firstActive.first : null;
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
      _selectedOffer = active.isNotEmpty ? active.first : null;
      _resetPointsInput();
    });
  }

  // ── OTP flow ──────────────────────────────────────────────────────────────

  Future<void> _sendOtpAndProceed() async {
    if (_sendingOtp || _pointsToRedeem == null) return;
    final offer = _selectedOffer ??
        const RedeemableOffer(
          id: 'gold-house-redeem',
          title: 'Gold House',
          description: '',
          business: 'Gold House',
          pointsCost: 0,
          companyPhoneNo: '0112948777',
        );
    setState(() => _sendingOtp = true);
    try {
      final otp = await widget.svc.sendRedemptionOtp(
        customerId: widget.member.userId,
        offerId: offer.id,
      );
      if (!mounted) return;
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpConfirmationScreen(
            member: widget.member,
            offer: offer,
            employeeId: widget.employeeId,
            svc: widget.svc,
            devOtp: otp,
            employee: widget.employee,
            pointsToRedeem: _pointsToRedeem!,
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
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
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
                    Text(
                      'For ${widget.member.name}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              
            ]),
          ),

          const SizedBox(height: 16),

          Expanded(child: _buildBody()),

          // ── Gold Shop: points input + confirm ─────────────────────────────
          if (!_loading && _error == null && _isGoldSelected)
            _GoldRedeemPanel(
              controller: _pointsController,
              customerPoints: widget.member.currentPoints,
              pointsError: _pointsError,
              pointsToRedeem: _pointsToRedeem,
              selectedOffer: _selectedOffer,
              sendingOtp: _sendingOtp,
              onPointsChanged: _onPointsChanged,
              onSendOtp: _sendOtpAndProceed,
            ),
        ]),
      ),
    );
  }

  // ── Company tab bar (kept for reference but not rendered) ─────────────────

  Widget _buildCompanyTabs() {
    final grouped = _grouped;
    final businesses = grouped.keys.toList();
    if (businesses.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: businesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final business = businesses[i];
          final theme = _BusinessTheme.of(business);
          final isActive = _selectedBusiness == business;
          final isGold = _selectedOffer?.business == business;

          return GestureDetector(
            onTap: () => _onTabTapped(business),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.color.withValues(alpha: 0.15)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: isActive
                      ? theme.color.withValues(alpha: 0.65)
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

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            GradientButton(
                label: 'Retry',
                onPressed: () {
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

// ── Gold Redeem Panel ─────────────────────────────────────────────────────────

class _GoldRedeemPanel extends StatelessWidget {
  final TextEditingController controller;
  final int customerPoints;
  final String? pointsError;
  final int? pointsToRedeem;
  final RedeemableOffer? selectedOffer;
  final bool sendingOtp;
  final ValueChanged<String> onPointsChanged;
  final VoidCallback onSendOtp;

  const _GoldRedeemPanel({
    required this.controller,
    required this.customerPoints,
    required this.pointsError,
    required this.pointsToRedeem,
    required this.selectedOffer,
    required this.sendingOtp,
    required this.onPointsChanged,
    required this.onSendOtp,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = !sendingOtp && pointsToRedeem != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section title ──────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.diamond_rounded,
                  size: 16, color: Color(0xFFFFD700)),
            ),
            const SizedBox(width: 10),
            Text(
              'Gold Shop Redemption',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
          ]),

          const SizedBox(height: 18),

          // ── Points input ───────────────────────────────────────────────
          _PointsInputField(
            controller: controller,
            customerPoints: customerPoints,
            errorText: pointsError,
            onChanged: onPointsChanged,
          ),

          const SizedBox(height: 14),

          // ── Selected summary ───────────────────────────────────────────
          if (selectedOffer != null) ...[
            _SelectedSummary(
              offer: selectedOffer!,
              customerPoints: customerPoints,
              overridePoints: pointsToRedeem,
            ),
            const SizedBox(height: 16),
          ],

          // ── CTA Button ─────────────────────────────────────────────────
          GradientButton(
            label: sendingOtp ? 'Sending OTP…' : 'Send OTP',
            icon: Icons.sms_rounded,
            onPressed: canSend ? onSendOtp : null,
          ),

          const SizedBox(height: 10),

          // ── Helper note ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_iphone_rounded,
                  size: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.6)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'OTP will be sent to the customer\'s registered number.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Points input field ────────────────────────────────────────────────────────

class _PointsInputField extends StatelessWidget {
  final TextEditingController controller;
  final int customerPoints;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _PointsInputField({
    required this.controller,
    required this.customerPoints,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Enter points to redeem',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),

        // Input box
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.error.withValues(alpha: 0.7)
                  : const Color(0xFFFFD700).withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            const Icon(Icons.stars_rounded,
                size: 20, color: Color(0xFFFFD700)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTextStyles.h4.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    fontSize: 24,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                'pts',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
        ),

        // Error
        if (hasError) ...[
          const SizedBox(height: 7),
          Row(children: [
            const SizedBox(width: 2),
            Icon(Icons.warning_amber_rounded,
                size: 13, color: AppColors.error),
            const SizedBox(width: 5),
            Text(
              errorText!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontSize: 11,
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

// ── Points summary card (active only, no expired) ─────────────────────────────

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
    final hasExpired = expiredTotalPoints > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + name + active pts ───────────────────────────
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(theme.icon, color: theme.color, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Points summary',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Active points badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.stars_rounded,
                    size: 13, color: Color(0xFFFFD700)),
                const SizedBox(width: 5),
                Text(
                  '$activeTotalPoints pts',
                  style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ]),
            ),
          ]),

          // ── Expiring soon row (only if exists) ───────────────────────────
          if (hasExpired) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.30)),
              ),
              child: Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: Color(0xFFFF6B35)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Points expiring soon',
                    style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFFF6B35),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$expiredTotalPoints pts',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFFF6B35),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Non-Gold notice ───────────────────────────────────────────────────────────

class _NonGoldNotice extends StatelessWidget {
  final String business;
  const _NonGoldNotice({required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.info_outline_rounded,
              size: 15,
              color: AppColors.textMuted.withValues(alpha: 0.7)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Redemption is only available for Gold Shop points.',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}

// ── Business theme ────────────────────────────────────────────────────────────

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
      default:
        return const _BusinessTheme(
          color: Color(0xFF34D399),
          accentColor: Color(0xFF6EE7B7),
          icon: Icons.local_gas_station_rounded,
          gradient: [Color(0xFF0F2027), Color(0xFF203A43)],
        );
    }
  }
}

// ── Selected summary strip ────────────────────────────────────────────────────

class _SelectedSummary extends StatelessWidget {
  final RedeemableOffer offer;
  final int customerPoints;
  final int? overridePoints;

  const _SelectedSummary({
    required this.offer,
    required this.customerPoints,
    this.overridePoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _BusinessTheme.of(offer.business);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(theme.icon, color: theme.color, size: 17),
        ),
        const SizedBox(width: 10),
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
              const SizedBox(height: 2),
              Text(
                offer.title,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}