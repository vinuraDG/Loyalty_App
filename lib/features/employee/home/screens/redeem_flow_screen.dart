// lib/features/employee/screens/redeem_flow_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';
import '../../../../models/user_model.dart';
import 'otp_confirmation_screen.dart';

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
  bool _redeeming = false;
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
    final available = _availablePoints;
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

  // ── Send OTP → navigate to OTP entry screen ──────────────────────────────

  Future<void> _confirmRedemption() async {
    if (_redeeming || _pointsToRedeem == null) return;
    final offer = _selectedOffer ??
        const RedeemableOffer(
          id: 'laundry-redeem',
          title: 'Sunshine Laundry',
          description: '',
          business: 'Sunshine Laundry',
          pointsCost: 0,
          companyPhoneNo: '0112948777',
        );
    setState(() => _redeeming = true);
    try {
      final otp = await widget.svc.sendRedemptionOtp(
        customerId:     widget.member.userId,
        offerId:        offer.id,
        pointsToRedeem: _pointsToRedeem!,
        companyPhoneNo: offer.companyPhoneNo,
      );
      if (!mounted) return;
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpConfirmationScreen(
            member:         widget.member,
            offer:          offer,
            employeeId:     widget.employeeId,
            svc:            widget.svc,
            employee:       widget.employee,
            pointsToRedeem: _pointsToRedeem!,
            initialOtp:     otp,
          ),
        ),
      );
      if (confirmed == true && mounted) {
        Navigator.pop(context, true);
      } else {
        if (mounted) setState(() => _redeeming = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _redeeming = false;
          _error = e is InsufficientPointsException
              ? 'Not enough points to complete this redemption.'
              : e.toString();
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  int get _availablePoints => _selectedOffer?.customerPoints ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(children: [
            // ── Header ──────────────────────────────────────────────────────
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

            _buildBody(),

            // ── Laundry: points input + confirm ─────────────────────────────
            if (!_loading && _error == null && _isGoldSelected)
              _LaundryRedeemPanel(
                controller: _pointsController,
                customerPoints: _availablePoints,
                pointsError: _pointsError,
                pointsToRedeem: _pointsToRedeem,
                redeeming: _redeeming,
                onPointsChanged: _onPointsChanged,
                onConfirm: _confirmRedemption,
              ),
          ]),
        ),
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
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
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
      );
    }

    if (_selectedBusiness == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text('No companies found.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: _CustomerPointsRow(
        totalPoints: widget.member.currentPoints,
        laundryPoints: _selectedOffer?.customerPoints ?? 0,
      ),
    );
  }
}

// ── Laundry Redeem Panel ──────────────────────────────────────────────────────

class _LaundryRedeemPanel extends StatelessWidget {
  final TextEditingController controller;
  final int customerPoints;
  final String? pointsError;
  final int? pointsToRedeem;
  final bool redeeming;
  final ValueChanged<String> onPointsChanged;
  final VoidCallback onConfirm;

  const _LaundryRedeemPanel({
    required this.controller,
    required this.customerPoints,
    required this.pointsError,
    required this.pointsToRedeem,
    required this.redeeming,
    required this.onPointsChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = !redeeming && pointsToRedeem != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section title ──────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_laundry_service_rounded,
                  size: 18, color: Color(0xFF60A5FA)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Redeem Points',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                  Text('Enter how many points to redeem',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      )),
                ],
              ),
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

          const SizedBox(height: 16),

          // ── CTA Button ─────────────────────────────────────────────────
          GradientButton(
            label: redeeming ? 'Sending OTP…' : 'Send OTP to Customer',
            icon: Icons.send_rounded,
            onPressed: canSend ? onConfirm : null,
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

// ── Customer points summary row ───────────────────────────────────────────────

class _CustomerPointsRow extends StatelessWidget {
  final int totalPoints;
  final int laundryPoints;

  const _CustomerPointsRow({
    required this.totalPoints,
    required this.laundryPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _StatCard(
          label: 'Total Points',
          value: '$totalPoints',
          icon: Icons.local_gas_station_rounded,
          iconColor: const Color(0xFF34D399),
          valueColor: const Color(0xFF34D399),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatCard(
          label: 'Laundry Points',
          value: '$laundryPoints',
          icon: Icons.local_laundry_service_rounded,
          iconColor: const Color(0xFF60A5FA),
          valueColor: const Color(0xFF60A5FA),
          highlight: true,
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: highlight ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: highlight ? 0.30 : 0.18),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'pts',
            style: TextStyle(
              color: valueColor.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

// ── Redemption success sheet ──────────────────────────────────────────────────

class _RedemptionSuccessSheet extends StatelessWidget {
  final RedemptionResult result;
  const _RedemptionSuccessSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF22C55E), size: 36),
          ),
          const SizedBox(height: 16),
          Text('Redemption Complete',
              style: AppTextStyles.h4
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            '${result.pointsDeducted} points redeemed successfully.',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confirmation',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
                Text(result.confirmationCode,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primaryLight)),
              ],
            ),
          ),
          if (result.remainingPoints > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Remaining points',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                  Text('${result.remainingPoints} pts',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: const Color(0xFFFFD700))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

