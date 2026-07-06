import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/features/auth/data/auth_api_service.dart';
import 'package:loyalty_app/features/auth/providers/auth_provider.dart';
import 'package:loyalty_app/features/employee/home/screens/employee_dashboard_screen.dart';
import 'package:loyalty_app/features/employee/employee_screens.dart';
import 'package:loyalty_app/customer/home/screens/main_screen.dart';
import 'package:loyalty_app/models/user_model.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import 'package:dio/dio.dart';

class DevBypassScreen extends ConsumerStatefulWidget {
  const DevBypassScreen({super.key});

  @override
  ConsumerState<DevBypassScreen> createState() => _DevBypassScreenState();
}

class _DevBypassScreenState extends ConsumerState<DevBypassScreen> {
  bool _loadingCustomer = false;
  bool _loadingEmployee = false;
  String? _error;

  // ── Customer fetch (unchanged — Common/GetCustomerByPhoneNo) ─────────────

  Future<UserModel> _fetchCustomer(String phone) async {
    final dio = ApiClient.instance.dio;
    final res = await dio.get('Common/GetCustomerByPhoneNo',
        queryParameters: {'CustomerPhoneNo': phone});

    final data = res.data;
    if (data == null || (data is String && data.trim().isEmpty) ||
        (data is Map && data.isEmpty)) {
      throw AuthException('No customer found for phone number $phone.');
    }
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Unexpected response from server.');
    }

    return UserModel(
      id: (data['Id'] ?? data['id'] ?? phone).toString(),
      firstName: (data['FirstName'] ?? '').toString(),
      lastName: (data['LastName'] ?? '').toString(),
      email: (data['Email'] ?? '').toString(),
      phone: (data['PhoneNo'] ?? phone).toString(),
      role: 'customer',
      totalPoints: int.tryParse(
              (data['TotalPoints'] ?? data['totalPoints'] ?? 0).toString()) ??
          0,
      address: (data['Address'] ?? '').toString(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _openAsCustomer() async {
    setState(() { _loadingCustomer = true; _error = null; });
    try {
      final user = await _fetchCustomer(AppConstants.devCustomerPhone);
      if (!mounted) return;
      await ref.read(authProvider.notifier).devLogin(user);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loadingCustomer = false; });
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.response!.data['Message'] ??
              'Could not fetch customer data')
          : 'Could not fetch customer data';
      if (mounted) setState(() { _error = msg.toString(); _loadingCustomer = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loadingCustomer = false; });
    }
  }

  // ── Employee fetch — now uses the dedicated employee endpoint ────────────

  Future<void> _openAsEmployee() async {
    setState(() { _loadingEmployee = true; _error = null; });
    try {
      final employee = await AuthApiService.instance
          .getEmployeeByPhone(AppConstants.devEmployeePhone);

      if (!mounted) return;
      await ref.read(authProvider.notifier).devLogin(employee);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => EmployeeDashboardScreen(employee: employee)),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loadingEmployee = false; });
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] ?? e.response!.data['Message'] ??
              'Could not fetch employee data')
          : 'Could not fetch employee data';
      if (mounted) setState(() { _error = msg.toString(); _loadingEmployee = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loadingEmployee = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              const Row(children: [
                AppLogo(size: 38),
                SizedBox(width: 10),
                Text('LoyaltyHub', style: AppTextStyles.h4),
                SizedBox(width: 10),
                _DevBadge(),
              ]),
              const SizedBox(height: 40),

              const Text('Dev Access', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Backend auth is not yet implemented.\nSelect a role to open the app with test data.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                  label: 'Test phone',
                  value: AppConstants.devCustomerPhone),
              const SizedBox(height: 40),

              // Customer card
              _RoleCard(
                icon: Icons.person_rounded,
                iconColor: AppColors.primaryLight,
                iconBg: AppColors.primaryLight.withValues(alpha: 0.12),
                title: 'Open as Customer',
                subtitle: 'Lakmal Perera · ${AppConstants.devCustomerPhone}',
                buttonLabel: 'Customer Dashboard',
                isLoading: _loadingCustomer,
                onTap: _loadingEmployee ? null : _openAsCustomer,
              ),
              const SizedBox(height: 16),

              // Employee card
              _RoleCard(
                icon: Icons.badge_rounded,
                iconColor: const Color(0xFFFFB347),
                iconBg: const Color(0xFFFFB347).withValues(alpha: 0.12),
                title: 'Open as Employee',
                subtitle: AppConstants.devEmployeePhone,
                buttonLabel: 'Employee Dashboard',
                isLoading: _loadingEmployee,
                onTap: _loadingCustomer ? null : _openAsEmployee,
              ),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error)),
                    ),
                  ]),
                ),
              ],

              const Spacer(),
              Center(
                child: Text(
                  'Disable by setting devBypass = false in AppConstants',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevBadge extends StatelessWidget {
  const _DevBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.4)),
      ),
      child: const Text(
        'DEV',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFFF97316),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label: ',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      Text(value,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: onTap == null
                ? AppColors.border
                : iconColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.labelMedium),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(buttonLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
      ]),
    );
  }
}