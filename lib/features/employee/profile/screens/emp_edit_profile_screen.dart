// lib/features/employee/profile/screens/emp_edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../data/emp_profile_api_service.dart';

class EmpEditProfileScreen extends StatefulWidget {
  final UserModel employee;
  const EmpEditProfileScreen({super.key, required this.employee});

  @override
  State<EmpEditProfileScreen> createState() => _EmpEditProfileScreenState();
}

class _EmpEditProfileScreenState extends State<EmpEditProfileScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _empIdCtrl;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _firstNameCtrl = TextEditingController(text: emp.firstName);
    _lastNameCtrl  = TextEditingController(text: emp.lastName);
    _emailCtrl     = TextEditingController(text: emp.email);
    _phoneCtrl     = TextEditingController(text: emp.phone);
    final rawId    = emp.id.toUpperCase();
    _empIdCtrl     = TextEditingController(
        text: '#${rawId.substring(0, rawId.length.clamp(0, 8))}');
    _loadFromApi();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _empIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFromApi() async {
    try {
      final info = await empProfileService.getProfileInfo(widget.employee.id);
      if (!mounted) return;
      if (info.firstName.isNotEmpty) _firstNameCtrl.text = info.firstName;
      if (info.lastName.isNotEmpty)  _lastNameCtrl.text  = info.lastName;
      if (info.email.isNotEmpty)     _emailCtrl.text     = info.email;
      if (info.phone.isNotEmpty)     _phoneCtrl.text     = info.phone;
    } catch (_) {}
  }

  String get _initials {
    final f = _firstNameCtrl.text.isNotEmpty
        ? _firstNameCtrl.text[0].toUpperCase() : '';
    final l = _lastNameCtrl.text.isNotEmpty
        ? _lastNameCtrl.text[0].toUpperCase() : '';
    return '$f$l';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [

          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('Edit Profile', style: AppTextStyles.h3),
              const Spacer(),
            ]),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Avatar ──────────────────────────────────────
                    Center(
                      child: InitialsAvatar(initials: _initials, size: 80),
                    ),
                    const SizedBox(height: 32),

                    const _SectionLabel(label: 'PERSONAL INFO'),
                    const SizedBox(height: 12),

                    _ProfileField(
                      controller: _firstNameCtrl,
                      label: 'First Name',
                      icon: Icons.person_outline_rounded,
                      readOnly: true,
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 14),

                    _ProfileField(
                      controller: _lastNameCtrl,
                      label: 'Last Name',
                      icon: Icons.person_outline_rounded,
                      readOnly: true,
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 14),

                    _ProfileField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      readOnly: true,
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 14),

                    _ProfileField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      readOnly: true,
                      hint: 'Verified via OTP',
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(children: [
                        const Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'Phone verified — cannot be changed here',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    _ProfileField(
                      controller: _empIdCtrl,
                      label: 'Employee ID',
                      icon: Icons.badge_outlined,
                      readOnly: true,
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Sub-widgets (mirrors customer edit_profile_screen.dart) ───────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.caption
          .copyWith(color: AppColors.textMuted, letterSpacing: 0.8));
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String                label;
  final IconData              icon;
  final TextInputType         keyboardType;
  final TextCapitalization    textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool                  readOnly;
  final String?               hint;
  final int                   maxLines;
  final String? Function(String?) validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType        = TextInputType.text,
    this.textCapitalization  = TextCapitalization.none,
    this.inputFormatters,
    this.readOnly            = false,
    this.hint,
    this.maxLines            = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:          controller,
    keyboardType:        keyboardType,
    textCapitalization:  textCapitalization,
    inputFormatters:     inputFormatters,
    readOnly:            readOnly,
    maxLines:            maxLines,
    validator:           validator,
    style: AppTextStyles.bodyMedium.copyWith(
        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary),
    decoration: InputDecoration(
      labelText:  label,
      hintText:   hint,
      hintStyle:  AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      suffixIcon: readOnly
          ? const Icon(Icons.lock_outline_rounded,
              color: AppColors.textMuted, size: 16)
          : null,
      filled:    true,
      fillColor: readOnly
          ? AppColors.bgCard.withOpacity(0.5)
          : AppColors.bgCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
