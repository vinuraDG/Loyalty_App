// lib/features/employee/screens/employee_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/screens/login_screen.dart';
import '../data/emp_profile_api_service.dart';
import 'change_password_page.dart';
import 'emp_edit_profile_screen.dart';

class EmployeeProfilePage extends ConsumerStatefulWidget {
  final UserModel employee;
  const EmployeeProfilePage({super.key, required this.employee});

  @override
  ConsumerState<EmployeeProfilePage> createState() =>
      _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends ConsumerState<EmployeeProfilePage> {
  final _svc = empProfileService;

  EmployeeProfileInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await _svc.getProfileInfo(widget.employee.id);
    if (!mounted) return;
    setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    final emp   = widget.employee;
    final phone = _info?.phone.isNotEmpty == true
        ? _info!.phone
        : emp.phone;
    final email = _info?.email.isNotEmpty == true
        ? _info!.email
        : emp.email;

    final f = emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : '';
    final l = emp.lastName.isNotEmpty  ? emp.lastName[0].toUpperCase()  : '';
    final initials = '$f$l';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.bgCard,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [

              // ── Header ────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Text('My Profile', style: AppTextStyles.h3),
                  Spacer(),
                ]),
              ),
              const SizedBox(height: 20),

              // ── User card ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    InitialsAvatar(initials: initials, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.name, style: AppTextStyles.h4),
                          const SizedBox(height: 3),
                          Text(phone, style: AppTextStyles.caption),
                          const SizedBox(height: 2),
                          Text(
                            'ID: #${emp.id.toUpperCase().substring(0, emp.id.length.clamp(0, 8))}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // ── Menu ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _MenuSection(title: 'Account', items: [

                    _MenuItem(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      color: AppColors.accentGold,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EmpEditProfileScreen(employee: emp),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _MenuSection(title: '', items: [
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      color: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () => _signOut(context, ref),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Sign-out helpers ──────────────────────────────────────────────────────────

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await _showSignOutDialog(context);
  if (!confirmed) return;
  await ref.read(authProvider.notifier).signOut();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

Future<bool> _showSignOutDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Sign out?',
                  style: AppTextStyles.h4, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text(
                "You'll need to sign back in to access the employee portal.",
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sign out',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          ),
        ),
      ) ??
      false;
}

// ── Menu widgets ──────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String          title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final isLast = e.key == items.length - 1;
                return Column(children: [
                  e.value,
                  if (!isLast)
                    const Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 0,
                        color: AppColors.border),
                ]);
              }).toList(),
            ),
          ),
        ],
      );
}

class _MenuItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String?      value;
  final Color        color;
  final Color?       textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.value,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
                color: textColor ?? AppColors.textPrimary, fontSize: 14),
          ),
          trailing: value != null
              ? Text(value!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted))
              : const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20),
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
      );
}
