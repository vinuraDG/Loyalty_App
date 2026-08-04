// lib/features/employee/screens/otp_confirmation_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';
import '../../../../models/user_model.dart';
import 'employee_dashboard_screen.dart'; // ← was employee_home_page.dart

class OtpConfirmationScreen extends StatefulWidget {
  final ScannedMember member;
  final RedeemableOffer offer;
  final String employeeId;
  final IEmpHomeService svc;
  final UserModel employee;
  final int pointsToRedeem;
  final String initialOtp;

  const OtpConfirmationScreen({
    super.key,
    required this.member,
    required this.offer,
    required this.employeeId,
    required this.svc,
    required this.employee,
    this.pointsToRedeem = 0,
    this.initialOtp = '',
  });

  @override
  State<OtpConfirmationScreen> createState() => _OtpConfirmationScreenState();
}

class _OtpConfirmationScreenState extends State<OtpConfirmationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _confirming = false;
  bool _resending  = false;
  String? _error;
  RedemptionResult? _result;
  String _displayedOtp = '';

  // Countdown
  static const _totalSeconds = 90;
  int _secondsLeft = _totalSeconds;
  bool _expired    = false;
  Timer? _timer;

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _displayedOtp = widget.initialOtp;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _totalSeconds;
      _expired     = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _expired = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    if (_resending) return;
    setState(() { _resending = true; _error = null; });
    for (final c in _controllers) c.clear();
    try {
      final newOtp = await widget.svc.sendRedemptionOtp(
        customerId:     widget.member.userId,
        offerId:        widget.offer.id,
        pointsToRedeem: widget.pointsToRedeem,
        companyPhoneNo: widget.offer.companyPhoneNo,
      );
      if (!mounted) return;
      setState(() {
        _resending = false;
        if (newOtp.isNotEmpty) _displayedOtp = newOtp;
      });
      _startTimer();
      _focusNodes[0].requestFocus();
    } catch (e) {
      if (mounted) setState(() { _resending = false; _error = e.toString(); });
    }
  }

  Color get _timerColor {
    if (_expired || _secondsLeft <= 10) return Colors.redAccent;
    if (_secondsLeft <= 30) return Colors.orange;
    return Colors.greenAccent;
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() => _error = null);
    // Do NOT auto-confirm on 4 digits — employee must press the button.
    // Auto-confirm races with the backend's OTP registration and always fails.
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _confirm() async {
    if (_otp.length < 4 || _confirming) return;
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      var result = await widget.svc.confirmRedemption(
        customerId: widget.member.userId,
        offerId:    widget.offer.id,
        otp:        _otp,
        employeeId: widget.employeeId,
        companyId:  widget.offer.companyId,
      );
      // Backend returns empty body on success — fill in values we already know.
      if (result.pointsDeducted == 0 && widget.pointsToRedeem > 0) {
        final remaining =
            (widget.offer.customerPoints - widget.pointsToRedeem).clamp(0, 999999);
        result = RedemptionResult(
          pointsDeducted:   widget.pointsToRedeem,
          remainingPoints:  remaining,
          confirmationCode: result.confirmationCode,
        );
      }
      if (mounted) setState(() => _result = result);
    } on InvalidOtpException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _confirming = false;
        });
        for (final c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
      }
    } on InsufficientPointsException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _confirming = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _SuccessView(
        result: _result!,
        member: widget.member,
        offer: widget.offer,
        employee: widget.employee,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [
          // ── App bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                onPressed: _confirming ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
              ),
              const Text('OTP Confirmation', style: AppTextStyles.h4),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── SMS sent illustration ──────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms_rounded,
                        color: AppColors.primaryLight, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('Enter Customer OTP',
                      style: AppTextStyles.h4, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the customer for the OTP sent to their phone, then type it below.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  if (widget.member.phone.isNotEmpty)
                    Text(
                      widget.member.phone,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primaryLight),
                    ),

                  // ── OTP display for employee ───────────────────────
                  if (_displayedOtp.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2744),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        Text(
                          'OTP Code',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _displayedOtp,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryLight,
                            letterSpacing: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer also received this via SMS',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Countdown timer ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(alignment: Alignment.center, children: [
                          CircularProgressIndicator(
                            value: _expired ? 0 : _secondsLeft / _totalSeconds,
                            strokeWidth: 3.5,
                            backgroundColor:
                                _timerColor.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_timerColor),
                          ),
                          Text(
                            _expired ? '0:00' : _timerLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _timerColor,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _expired
                                ? 'OTP Expired'
                                : 'Code expires in $_timerLabel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _timerColor,
                            ),
                          ),
                          if (!_expired)
                            Text(
                              'Ask customer for the code',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // ── Resend button (shown when expired) ────────────
                  if (_expired) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resending ? null : _resendOtp,
                        icon: _resending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryLight),
                              )
                            : const Icon(Icons.refresh_rounded,
                                color: AppColors.primaryLight, size: 18),
                        label: Text(
                          _resending ? 'Sending OTP…' : 'Resend OTP',
                          style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: AppColors.primaryLight.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Redemption summary ─────────────────────────────
                  _RedemptionSummary(
                    member: widget.member,
                    offer: widget.offer,
                    pointsToRedeem: widget.pointsToRedeem,
                  ),
                  const SizedBox(height: 28),

                  // ── OTP input boxes ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          hasError: _error != null,
                          enabled: !_expired && !_confirming,
                          onChanged: (v) => _onDigitEntered(i, v),
                          onKeyEvent: (ev) => _onKeyEvent(i, ev),
                        ),
                      );
                    }),
                  ),

                  // ── Error message ──────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.redAccent)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Confirm button ─────────────────────────────────
                  GradientButton(
                    label: _confirming ? 'Confirming…' : 'Confirm Redemption',
                    icon: Icons.check_circle_rounded,
                    onPressed: (_otp.length == 4 && !_confirming && !_expired)
                        ? _confirm
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── OTP digit input box ───────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    this.enabled = true,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: 60,
        height: 68,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.bgCard,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: hasError
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color:
                      hasError ? Colors.redAccent : AppColors.primaryLight,
                  width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Redemption summary card ───────────────────────────────────────────────────

class _RedemptionSummary extends StatelessWidget {
  final ScannedMember member;
  final RedeemableOffer offer;
  final int pointsToRedeem;

  const _RedemptionSummary({
    required this.member,
    required this.offer,
    required this.pointsToRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = offer.customerPoints - pointsToRedeem;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Redemption Details',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        _Row(label: 'Customer', value: member.name),
        const SizedBox(height: 8),
        _Row(label: 'Earn Company', value: offer.business),
        const SizedBox(height: 8),
        _Row(label: 'Points to redeem', value: '$pointsToRedeem pts'),
        const SizedBox(height: 8),
        _Row(
          label: 'Remaining after',
          value: '${remaining > 0 ? remaining : 0} pts',
          valueColor: Colors.greenAccent,
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted)),
      ),
      Text(
        value,
        style: AppTextStyles.caption.copyWith(
          color: valueColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final RedemptionResult result;
  final ScannedMember member;
  final RedeemableOffer offer;
  final UserModel employee;

  const _SuccessView({
    required this.result,
    required this.member,
    required this.offer,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.greenAccent, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Redemption Successful!',
                  style: AppTextStyles.h3, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                '${offer.title} has been applied for ${member.name}.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  _ConfirmRow(
                      icon: Icons.tag_rounded,
                      label: 'Confirmation Code',
                      value: result.confirmationCode),
                  const SizedBox(height: 12),
                  _ConfirmRow(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'Points Deducted',
                      value: '−${result.pointsDeducted}',
                      valueColor: Colors.redAccent),
                  const SizedBox(height: 12),
                  _ConfirmRow(
                      icon: Icons.stars_rounded,
                      label: 'Remaining Points',
                      value: '${result.remainingPoints}',
                      valueColor: const Color(0xFFFFD700)),
                ]),
              ),

              const SizedBox(height: 32),

              GradientButton(
                label: 'Done',
                icon: Icons.check_rounded,
                // ── KEY FIX: push EmployeeDashboardScreen (has bottom nav)
                // instead of EmployeeHomePage (bare page, no bottom nav)
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EmployeeDashboardScreen(employee: employee),
                  ),
                  (route) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 10),
      Expanded(
          child: Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted))),
      Text(value,
          style: AppTextStyles.labelMedium
              .copyWith(color: valueColor ?? AppColors.textPrimary)),
    ]);
  }
}