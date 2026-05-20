import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class EmployeeProfilePage extends ConsumerWidget {
  final UserModel employee;
  const EmployeeProfilePage({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawId = employee.id.toUpperCase();
    final shortId = rawId.substring(0, rawId.length.clamp(0, 8));

    Future<void> signOut() async {
      await ref.read(authProvider.notifier).signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
              Text('Profile', style: AppTextStyles.h3),
              const SizedBox(height: 24),

              // ── Avatar + name card ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  InitialsAvatar(initials: employee.initials, size: 64),
                  const SizedBox(height: 12),
                  Text(employee.name, style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text('Employee ID: #$shortId',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text('Staff Member',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Account section ───────────────────────────────────
              Text('Account', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _ProfileTile(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: employee.name,
              ),
              _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'Employee ID',
                value: '#$shortId',
              ),
              _ProfileTile(
                icon: Icons.work_outline_rounded,
                label: 'Role',
                value: 'Staff Member',
              ),
              const SizedBox(height: 24),

              // ── App section ───────────────────────────────────────
              Text('App', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _ProfileTile(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                value: '1.0.0',
              ),
              const SizedBox(height: 24),

              // ── Sign out ──────────────────────────────────────────
              GestureDetector(
                onTap: signOut,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Text('Sign Out',
                          style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.redAccent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.primaryLight, size: 20),
        const SizedBox(width: 14),
        Expanded(
            child: Text(label, style: AppTextStyles.bodySmall)),
        Text(value,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted)),
      ]),
    );
  }
}