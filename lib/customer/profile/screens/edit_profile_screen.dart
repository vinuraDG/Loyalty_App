import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'change_password_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  bool _isSaving   = false;
  bool _hasChanges = false;

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

  String get _initials {
    final f = _firstNameCtrl.text.isNotEmpty
        ? _firstNameCtrl.text[0].toUpperCase() : '';
    final l = _lastNameCtrl.text.isNotEmpty
        ? _lastNameCtrl.text[0].toUpperCase() : '';
    return '$f$l';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    // TODO: wire to authProvider.updateProfile(...)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() { _isSaving = false; _hasChanges = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    Navigator.pop(context);
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    if (!_hasChanges) { Navigator.pop(context); return; }
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Discard changes?', style: AppTextStyles.h4),
        content: const Text(
          'You have unsaved changes. Are you sure you want to go back?',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep editing',
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard',
                style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (discard == true && context.mounted) Navigator.pop(context);
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
              const Text('Edit Profile', style: AppTextStyles.h3),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Avatar ────────────────────────────────────────
                    Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_firstNameCtrl, _lastNameCtrl]),
                        builder: (_, __) =>
                            InitialsAvatar(initials: _initials, size: 80),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Personal Info Form ────────────────────────────
                    const _SectionLabel(label: 'PERSONAL INFO'),
                    const SizedBox(height: 12),

                    _ProfileField(
                      controller: _firstNameCtrl,
                      label: 'First Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'First name is required';
                        if (v.trim().length < 2) return 'Too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _ProfileField(
                      controller: _lastNameCtrl,
                      label: 'Last Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Last name is required';
                        if (v.trim().length < 2) return 'Too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _ProfileField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        final emailRegex =
                            RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                        return null;
                      },
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
                      controller: _addressCtrl,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 2,
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 28),

                    // ── Security section ──────────────────────────────
                    const _SectionLabel(label: 'SECURITY'),
                    const SizedBox(height: 12),

                    _ChangePasswordTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    GradientButton(
                      label: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: _hasChanges ? _save : null,
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

// ── Change Password Tile ──────────────────────────────────────────────────────

class _ChangePasswordTile extends StatelessWidget {
  final VoidCallback onTap;
  const _ChangePasswordTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Update your account password',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textSecondary,
            size: 14,
          ),
        ]),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted, letterSpacing: 0.8));
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
        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}