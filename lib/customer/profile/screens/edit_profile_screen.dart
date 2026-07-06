import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';

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

  // Snapshot of values AT screen-open time — never updated after save
  // so _onChanged always compares against the original baseline.
  late String _origFirstName;
  late String _origLastName;
  late String _origEmail;
  late String _origAddress;

  bool _isSaving   = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);

    // Capture baseline ONCE
    _origFirstName = user?.firstName ?? '';
    _origLastName  = user?.lastName  ?? '';
    _origEmail     = user?.email     ?? '';
    _origAddress   = user?.address   ?? '';

    _firstNameCtrl = TextEditingController(text: _origFirstName);
    _lastNameCtrl  = TextEditingController(text: _origLastName);
    _emailCtrl     = TextEditingController(text: _origEmail);
    _phoneCtrl     = TextEditingController(text: user?.phone ?? '');
    _addressCtrl   = TextEditingController(text: _origAddress);

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
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    // Compare against the ORIGINAL baseline, not the current provider state.
    // This prevents the re-save loop where a successful update refreshes the
    // provider, which triggers _onChanged, which sets _hasChanges = true again.
    final changed =
        _firstNameCtrl.text != _origFirstName ||
        _lastNameCtrl.text  != _origLastName  ||
        _emailCtrl.text     != _origEmail     ||
        _addressCtrl.text   != _origAddress;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  String get _initials {
    final f = _firstNameCtrl.text.isNotEmpty
        ? _firstNameCtrl.text[0].toUpperCase() : '';
    final l = _lastNameCtrl.text.isNotEmpty
        ? _lastNameCtrl.text[0].toUpperCase() : '';
    return '$f$l';
  }

  /// Formats a raw exception message for display:
  /// strips the ugly "Exception: " prefix that Dart adds by default.
  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) return raw.substring('Exception: '.length);
    return raw;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    try {
      await ref.read(authProvider.notifier).updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName:  _lastNameCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        address:   _addressCtrl.text.trim(),
      );
      if (!mounted) return;

      // Update the baseline so _onChanged no longer sees a difference.
      // Do this BEFORE setState so the listener fires with the right baseline.
      _origFirstName = _firstNameCtrl.text.trim();
      _origLastName  = _lastNameCtrl.text.trim();
      _origEmail     = _emailCtrl.text.trim();
      _origAddress   = _addressCtrl.text.trim();

      setState(() { _isSaving = false; _hasChanges = false; });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Profile updated successfully!'),
            ]),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      Navigator.pop(context);

    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_friendlyError(e))),
            ]),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
    }
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
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primaryLight)),
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

    return PopScope(
      // Intercept the Android back gesture / button
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: Column(children: [

            // ── Header ──────────────────────────────────────────────
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

                      // ── Avatar ───────────────────────────────────
                      Center(
                        child: AnimatedBuilder(
                          animation: Listenable.merge(
                              [_firstNameCtrl, _lastNameCtrl]),
                          builder: (_, __) =>
                              InitialsAvatar(initials: _initials, size: 80),
                        ),
                      ),
                      const SizedBox(height: 32),

                      const _SectionLabel(label: 'PERSONAL INFO'),
                      const SizedBox(height: 12),

                      _ProfileField(
                        controller: _firstNameCtrl,
                        label: 'First Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'First name is required';
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
                          if (v == null || v.trim().isEmpty)
                            return 'Last name is required';
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
                      const SizedBox(height: 32),

                      GradientButton(
                        label: 'Save Changes',
                        isLoading: _isSaving,
                        onPressed: _hasChanges && !_isSaving ? _save : null,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
      // FIX: withValues(alpha:) is Flutter 3.27+ only — use withOpacity instead
      fillColor: readOnly
          ? AppColors.bgCard.withOpacity(0.5)
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}