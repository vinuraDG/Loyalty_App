// lib/features/employee/screens/otp_confirmation_screen.dart

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
  final String devOtp;
  final UserModel employee;
  final int pointsToRedeem;

  const OtpConfirmationScreen({
    super.key,
    required this.member,
    required this.offer,
    required this.employeeId,
    required this.svc,
    required this.employee,
    this.devOtp = '',
    this.pointsToRedeem = 0,
  });

  @override
  State<OtpConfirmationScreen> createState() => _OtpConfirmationScreenState();
}

class _OtpConfirmationScreenState extends State<OtpConfirmationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _confirming = false;
  String? _error;
  RedemptionResult? _result;

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() => _error = null);
    if (_otp.length == 4) _confirm();
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
      final result = await widget.svc.confirmRedemption(
        customerId: widget.member.userId,
        offerId: widget.offer.id,
        otp: _otp,
        employeeId: widget.employeeId,
        pointsToRedeem: widget.pointsToRedeem,
        companyPhoneNo: widget.offer.companyPhoneNo,
      );
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
                  const Text('OTP Sent to Customer',
                      style: AppTextStyles.h4, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'A 4-digit code was sent to the customer\'s phone.\nAsk them to read it aloud and enter it below.',
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

                  // ── Dev hint (mock only) ───────────────────────────
                  if (widget.devOtp.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.developer_mode_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(
                              text: 'Dev mode OTP: ',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.amber),
                            ),
                            TextSpan(
                              text: widget.devOtp,
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 3),
                            ),
                          ])),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Redemption summary ─────────────────────────────
                  _RedemptionSummary(
                    member: widget.member,
                    offer: widget.offer,
                    pointsToRedeem: widget.pointsToRedeem,
                  ),
                  const SizedBox(height: 32),

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
                    onPressed:
                        (_otp.length == 4 && !_confirming) ? _confirm : null,
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
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
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
    final remaining = member.currentPoints - pointsToRedeem;
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