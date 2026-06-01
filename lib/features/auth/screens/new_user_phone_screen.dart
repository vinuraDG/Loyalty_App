import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/features/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';

/// Shown after OTP verification when the phone number has no existing account.
/// Collects first name, last name, and email to create a new account.
class NewUserPhoneScreen extends ConsumerStatefulWidget {
  const NewUserPhoneScreen({super.key});

  @override
  ConsumerState<NewUserPhoneScreen> createState() =>
      _NewUserPhoneScreenState();
}

class _NewUserPhoneScreenState extends ConsumerState<NewUserPhoneScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).createAccountWithPhone(
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
      _emailCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ref.read(authProvider).isAuthenticated) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)));
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Complete your profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AppLogo(size: 56)),
                const SizedBox(height: 20),
                const Center(
                  child: Text('One last step', style: AppTextStyles.h2),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    "We'll set up your LoyaltyHub account.",
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                Row(children: [
                  Expanded(
                    child: AppTextField(
                      label: 'First name',
                      hint: 'Kasun',
                      controller: _firstNameCtrl,
                      keyboardType: TextInputType.name,
                      prefixIconData: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Too short';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Last name',
                      hint: 'Perera',
                      controller: _lastNameCtrl,
                      keyboardType: TextInputType.name,
                      prefixIconData: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Too short';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIconData: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                GradientButton(
                  label: 'Create Account',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: auth.isLoading,
                  onPressed: _createAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}