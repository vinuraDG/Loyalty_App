import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/customer/profile/data/profile_api_service.dart';
import 'package:loyalty_app/customer/profile/screens/change_password_screen.dart';
import 'package:loyalty_app/customer/profile/screens/edit_profile_screen.dart';
import 'package:loyalty_app/customer/qr/screens/qr_screen.dart';
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

  Future<void> _refresh() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await appRefresh(ref);
    final newFuture = _svc.getProfileSummary(userId);
    setState(() => _summaryFuture = newFuture);
    await newFuture;
  }

  // ── Sign-out: see top-level _signOut() below ─────────────────────────────


  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    ref.listen<int>(appRefreshKeyProvider, (_, __) => _refresh());

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
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const QrScreen())),
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
                    onTap: () => _deleteAccount(context, ref),
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

Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
  // Step 1 — warning
  final proceed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: false,
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
            child: const Icon(Icons.delete_forever_rounded,
                color: AppColors.error, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Delete Account?',
              style: AppTextStyles.h4, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'This will permanently delete your account, all your loyalty points, and transaction history. This cannot be undone.',
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
              child: const Text('Continue',
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
  ) ?? false;
  if (!proceed || !context.mounted) return;

  // Step 2 — type DELETE to confirm
  final confirmCtrl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Confirm deletion', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            Text(
              'Type DELETE to permanently remove your account:',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmCtrl,
              autofocus: true,
              onChanged: (_) => setS(() {}),
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle:
                    AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgDark,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmCtrl.text.trim() == 'DELETE'
                      ? AppColors.error
                      : AppColors.bgDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: confirmCtrl.text.trim() == 'DELETE'
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('Delete my account',
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
    ),
  ) ?? false;
  confirmCtrl.dispose();
  if (!confirmed || !context.mounted) return;

  // Step 3 — call API and navigate out
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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