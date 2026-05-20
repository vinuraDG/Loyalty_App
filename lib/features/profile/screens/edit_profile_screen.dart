import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  // Password change controllers
  final TextEditingController _currentPassCtrl  = TextEditingController();
  final TextEditingController _newPassCtrl       = TextEditingController();
  final TextEditingController _confirmPassCtrl   = TextEditingController();

  bool _isSaving         = false;
  bool _isChangingPass   = false;
  bool _hasChanges       = false;
  bool _showCurrentPass  = false;
  bool _showNewPass      = false;
  bool _showConfirmPass  = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl  = TextEditingController(text: user?.lastName  ?? '');
    _emailCtrl     = TextEditingController(text: user?.email     ?? '');
    _phoneCtrl     = TextEditingController(text: user?.phone     ?? '');
    _addressCtrl   = TextEditingController(text: user?.address   ?? '');

    for (final c in [_firstNameCtrl, _lastNameCtrl, _emailCtrl, _addressCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl,
      _phoneCtrl, _addressCtrl,
      _currentPassCtrl, _newPassCtrl, _confirmPassCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    final user = ref.read(currentUserProvider);
    final changed =
        _firstNameCtrl.text != (user?.firstName ?? '') ||
        _lastNameCtrl.text  != (user?.lastName  ?? '') ||
        _emailCtrl.text     != (user?.email     ?? '') ||
        _addressCtrl.text   != (user?.address   ?? '');
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  // ── Build initials from first + last name ─────────────────────────────────
  String get _initials {
    final f = _firstNameCtrl.text.isNotEmpty
        ? _firstNameCtrl.text[0].toUpperCase()
        : '';
    final l = _lastNameCtrl.text.isNotEmpty
        ? _lastNameCtrl.text[0].toUpperCase()
        : '';
    return '$f$l';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    // TODO: wire to authProvider.updateProfile(firstName, lastName, email, address)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() { _isSaving = false; _hasChanges = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    Navigator.pop(context);
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isChangingPass = true);
    FocusScope.of(context).unfocus();

    // TODO: wire to authProvider.changePassword(_currentPassCtrl.text, _newPassCtrl.text)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isChangingPass = false);
    _currentPassCtrl.clear();
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

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
                onPressed: () => _confirmDiscard(context),
              ),
              Text('Edit Profile', style: AppTextStyles.h3),
              const Spacer(),
              if (_hasChanges)
                TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text('Save',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primary)),
                ),
            ]),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Avatar — always initials, no photo change ────
                  Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(
                          [_firstNameCtrl, _lastNameCtrl]),
                      builder: (_, __) =>
                          InitialsAvatar(initials: _initials, size: 80),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Personal Info ────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: 'Personal Info'),
                        const SizedBox(height: 12),

                        // First Name
                        _ProfileField(
                          controller: _firstNameCtrl,
                          label: 'First Name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'First name is required';
                            if (v.trim().length < 2)
                              return 'Too short';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Last Name
                        _ProfileField(
                          controller: _lastNameCtrl,
                          label: 'Last Name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Last name is required';
                            if (v.trim().length < 2)
                              return 'Too short';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _ProfileField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Email is required';
                            final emailRegex =
                                RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v.trim()))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone — read-only
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
                                  color: AppColors.textMuted,
                                  fontSize: 11),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),

                        // Address
                        _ProfileField(
                          controller: _addressCtrl,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          keyboardType: TextInputType.streetAddress,
                          maxLines: 2,
                          validator: (_) => null, // optional field
                        ),
                        const SizedBox(height: 28),

                        // ── Loyalty Info (read-only) ───────────────
                        _SectionLabel(label: 'Loyalty Info'),
                        const SizedBox(height: 12),
                        _ReadOnlyInfoRow(
                          icon: Icons.stars_rounded,
                          color: AppColors.primary,
                          label: 'Total Points',
                          value: '${user.totalPoints} pts',
                        ),
                        const SizedBox(height: 10),
                        _ReadOnlyInfoRow(
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.accentGold,
                          label: 'Current Tier',
                          value: user.loyaltyTier,
                        ),
                        const SizedBox(height: 10),
                        _ReadOnlyInfoRow(
                          icon: Icons.military_tech_rounded,
                          color: AppColors.fuelColor,
                          label: 'Points to Next Tier',
                          value: '${user.pointsToNextTier} pts',
                        ),
                        const SizedBox(height: 28),

                        // ── Save button ───────────────────────────
                        GradientButton(
                          label: 'Save Changes',
                          isLoading: _isSaving,
                          onPressed: _hasChanges ? _save : null,
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),

                  // ── Change Password section ──────────────────────
                  _SectionLabel(label: 'Change Password'),
                  const SizedBox(height: 12),

                  Form(
                    key: _passwordFormKey,
                    child: Column(children: [
                      _PasswordField(
                        controller: _currentPassCtrl,
                        label: 'Current Password',
                        visible: _showCurrentPass,
                        onToggle: () => setState(
                            () => _showCurrentPass = !_showCurrentPass),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Enter your current password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _PasswordField(
                        controller: _newPassCtrl,
                        label: 'New Password',
                        visible: _showNewPass,
                        onToggle: () =>
                            setState(() => _showNewPass = !_showNewPass),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Enter a new password';
                          if (v.length < 8)
                            return 'Password must be at least 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _PasswordField(
                        controller: _confirmPassCtrl,
                        label: 'Confirm New Password',
                        visible: _showConfirmPass,
                        onToggle: () => setState(
                            () => _showConfirmPass = !_showConfirmPass),
                        validator: (v) {
                          if (v != _newPassCtrl.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Update Password',
                        isLoading: _isChangingPass,
                        onPressed: _changePassword,
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    if (!_hasChanges) { Navigator.pop(context); return; }
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('Discard changes?', style: AppTextStyles.h4),
        content: Text(
            'You have unsaved changes. Are you sure you want to go back?',
            style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep editing',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primaryLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (discard == true && context.mounted) Navigator.pop(context);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.caption
          .copyWith(color: AppColors.textMuted, letterSpacing: 0.5));
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? hint;
  final int maxLines;
  final String? Function(String?) validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    readOnly: readOnly,
    maxLines: maxLines,
    validator: validator,
    style: AppTextStyles.bodyMedium.copyWith(
        color: readOnly
            ? AppColors.textSecondary
            : AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle:
          AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      labelStyle:
          AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      suffixIcon: readOnly
          ? const Icon(Icons.lock_outline_rounded,
              color: AppColors.textMuted, size: 16)
          : null,
      filled: true,
      fillColor: readOnly
          ? AppColors.bgCard.withValues(alpha: 0.5)
          : AppColors.bgCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: !visible,
    validator: validator,
    style: AppTextStyles.bodyMedium
        .copyWith(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle:
          AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      prefixIcon: const Icon(Icons.lock_outline_rounded,
          color: AppColors.primary, size: 20),
      suffixIcon: IconButton(
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 18,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: AppColors.bgCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

class _ReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _ReadOnlyInfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(width: 14),
      Text(label, style: AppTextStyles.caption),
      const Spacer(),
      Text(value,
          style:
              AppTextStyles.labelMedium.copyWith(fontSize: 13)),
    ]),
  );
}