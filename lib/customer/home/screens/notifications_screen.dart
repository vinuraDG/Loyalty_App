import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import 'package:loyalty_app/features/auth/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _checkLoading = false;
  String? _errorText;

  Future<void> _checkVerified() async {
    setState(() {
      _checkLoading = true;
      _errorText = null;
    });
    await ref.read(authProvider.notifier).refreshEmailStatus();
    if (!mounted) return;
    setState(() => _checkLoading = false);

    final user = ref.read(currentUserProvider);
    if (user?.emailConfirmed == true) {
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Email not verified yet. Check your inbox and click the link.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ]),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final emailConfirmed = user?.emailConfirmed ?? true;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: emailConfirmed
            ? _buildEmpty()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildEmailVerifyCard(user?.email ?? ''),
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              color: AppColors.textSecondary, size: 64),
          SizedBox(height: 16),
          Text('All clear', style: AppTextStyles.h3),
          SizedBox(height: 8),
          Text('You have no notifications.',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildEmailVerifyCard(String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_unread_outlined,
                  color: AppColors.accentGold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verify your email',
                      style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    email.isNotEmpty ? email : 'No email set',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.accentGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Action required',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.accentGold, fontSize: 10),
              ),
            ),
          ]),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          Text(
            'We\'ve sent a verification link to your email address. '
            'Click the link in the email to confirm your account.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.6),
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: _errorText!),
          ],

          const SizedBox(height: 20),

          // ── "I've already verified" button ─────────────────────────
          GestureDetector(
            onTap: _checkLoading ? null : _checkVerified,
            child: AnimatedOpacity(
              opacity: _checkLoading ? 0.55 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.buttonGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _checkLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_outlined,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "I've already verified",
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
