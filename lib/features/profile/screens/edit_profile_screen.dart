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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl  = TextEditingController(text: user?.name  ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');

    _nameCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged);
    _phoneCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    final user = ref.read(currentUserProvider);
    final changed = _nameCtrl.text  != (user?.name  ?? '') ||
                    _emailCtrl.text != (user?.email ?? '') ||
                    _phoneCtrl.text != (user?.phone ?? '');
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    // TODO: wire to your actual update method in authProvider
    // e.g. await ref.read(authProvider.notifier).updateProfile(...)
    await Future.delayed(const Duration(seconds: 1)); // simulated save

    if (!mounted) return;
    setState(() { _isSaving = false; _hasChanges = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    Navigator.pop(context);
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
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary)),
                ),
            ]),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Avatar ──────────────────────────────────────
                  Center(
                    child: Stack(children: [
                      InitialsAvatar(initials: user.initials, size: 80),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bgDark, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 13),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Change photo',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryLight)),
                  ),
                  const SizedBox(height: 32),

                  // ── Personal Info section ────────────────────────
                  _SectionLabel(label: 'Personal Info'),
                  const SizedBox(height: 12),

                  _ProfileField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      if (v.trim().length < 2) return 'Name too short';
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
                      final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phone — read-only (tied to auth)
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
                      Text('Phone verified — cannot be changed here',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted, fontSize: 11)),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── Loyalty Info section (read-only) ─────────────
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
                  const SizedBox(height: 36),

                  // ── Save button ──────────────────────────────────
                  GradientButton(
                    label: 'Save Changes',
                    isLoading: _isSaving,
                    onPressed: _hasChanges ? _save : null,
                  ),
                  const SizedBox(height: 24),
                ]),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Discard changes?', style: AppTextStyles.h4),
        content: Text('You have unsaved changes. Are you sure you want to go back?',
          style: AppTextStyles.bodySmall),
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
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
    style: AppTextStyles.caption.copyWith(
      color: AppColors.textMuted, letterSpacing: 0.5));
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? hint;
  final String? Function(String?) validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    readOnly: readOnly,
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

class _ReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _ReadOnlyInfoRow({
    required this.icon, required this.color,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      Text(value, style: AppTextStyles.labelMedium.copyWith(fontSize: 13)),
    ]),
  );
}