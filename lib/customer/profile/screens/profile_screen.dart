import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/customer/profile/data/profile_api_service.dart';
import 'package:loyalty_app/customer/profile/screens/change_password_screen.dart';
import 'package:loyalty_app/customer/profile/screens/edit_profile_screen.dart';
import 'package:loyalty_app/customer/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../core/providers/refresh_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final IProfileService? service; // injectable for testing
  const ProfileScreen({super.key, this.service});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  IProfileService get _svc =>
      widget.service ?? profileService;

  Future<ProfileSummary>? _summaryFuture;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      _summaryFuture = _svc.getProfileSummary(userId);
    }
  }

  Future<void> _reload() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final newFuture = _svc.getProfileSummary(userId);
    setState(() { _summaryFuture = newFuture; });
    await newFuture;
  }

  Future<void> _refresh() async {
    await appRefresh(ref);
    await _reload();
  }

  // ── Sign-out: see top-level _signOut() below ─────────────────────────────


  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    ref.listen<int>(appRefreshKeyProvider, (prev, next) {
      if (prev != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reload();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.bgCard,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [
            // ── Header ──────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Text('My Profile', style: AppTextStyles.h3),
                Spacer(),
              ]),
            ),
            const SizedBox(height: 20),

            // ── User card with async loyalty summary ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: FutureBuilder<ProfileSummary>(
                  future: _summaryFuture,
                  builder: (context, snap) {
                    // Tier from snapshot when ready, otherwise from user model
                    // as a local fallback so the card never shows blank.
                    final tier = snap.data?.loyaltyTier ?? user.loyaltyTier;

                    return Row(children: [
                      InitialsAvatar(
                        initials: _initials(user.firstName, user.lastName),
                        size: 64,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 3),
                            Text(user.email, style: AppTextStyles.caption),
                            const SizedBox(height: 2),
                            Text(user.phone, style: AppTextStyles.caption),
                            
                          ],
                        ),
                      ),
                    ]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Menu ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                _MenuSection(title: 'Account', items: [
                  _MenuItem(
                    icon: Icons.qr_code_rounded,
                    label: 'My QR Code',
                    color: AppColors.primary,
                    onTap: () => context
                        .findAncestorStateOfType<MainScreenState>()
                        ?.setIndex(2),
                  ),
                  _MenuItem(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    color: AppColors.accentGold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    color: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => _deleteAccount(context, ref, user.totalPoints),
                  ),
                ]),
                const SizedBox(height: 12),
                _MenuSection(title: 'Support', items: [
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    color: AppColors.golfColor,
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    color: AppColors.textSecondary,
                    onTap: () {},
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

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty  ? last[0].toUpperCase()  : '';
    return '$f$l';
  }
}

// ── Sign-out helpers (top-level so Riverpod inspector can't mis-reflect them) ─

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

Future<void> _deleteAccount(
    BuildContext context, WidgetRef ref, int totalPoints) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Icon
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25), width: 1.5),
            ),
            child: const Icon(Icons.delete_forever_rounded,
                color: AppColors.error, size: 32),
          ),
          const SizedBox(height: 18),

          // Title
          const Text(
            'Delete Account?',
            style: AppTextStyles.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Points destruction warning banner
          if (totalPoints > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error, height: 1.5),
                        children: [
                          const TextSpan(
                              text: 'You are about to delete this account. '),
                          TextSpan(
                            text:
                                'Your $totalPoints loyalty point${totalPoints == 1 ? '' : 's'} '
                                'under this account will be permanently destroyed',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          const TextSpan(text: ' and cannot be recovered.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // General warning
          Text(
            totalPoints > 0
                ? 'Your account and all transaction history will also be permanently removed.'
                : 'You are about to delete this account. Your account and all transaction history will be permanently removed and cannot be recovered.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Delete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Delete Account',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),

          // Keep account button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep My Account',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ]),
      ),
    ),
  ) ?? false;

  if (!confirmed || !context.mounted) return;

  // ── Step 2: type DELETE to confirm ──────────────────────────────────────
  final ctrl = TextEditingController();
  final typed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.keyboard_outlined,
                color: AppColors.error, size: 32),
            const SizedBox(height: 14),
            const Text('Final confirmation',
                style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text(
              'Type DELETE in the box below to permanently delete your account.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted, letterSpacing: 2),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setS(() {}),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctrl.text.trim() == 'DELETE'
                      ? AppColors.error
                      : AppColors.error.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: ctrl.text.trim() == 'DELETE'
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('Delete My Account',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    ),
  );
  // Dispose after the next frame so the focus system can finish its
  // cleanup callbacks before the controller is torn down.
  WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());

  if (typed != true || !context.mounted) return;

  // Call API and navigate out
  try {
    await ref.read(authProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  } catch (e) {
    if (!context.mounted) return;
    final msg = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
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

Future<bool> _showSignOutDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 60, height: 60,
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
                "You'll need to sign back in to access your loyalty points and rewards.",
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
  final String       title;
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
  final Color        color;
  final Color?       textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
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
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 20),
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
      );
}