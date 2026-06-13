// lib/features/employee/profile/data/emp_profile_api_service.dart

import 'package:loyalty_app/core/constants/app_constants.dart';
import 'emp_profile_mock_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class EmployeeProfileInfo {
  final String phone;
  final String title;

  const EmployeeProfileInfo({required this.phone, required this.title});

  factory EmployeeProfileInfo.fromJson(Map<String, dynamic> json) =>
      EmployeeProfileInfo(
        phone: json['phone'] as String? ?? '—',
        title: json['title'] as String? ?? 'Staff Member',
      );
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IEmpProfileService {
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId);
  Future<void> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
  });
}

// ── Real API service (stubs) ──────────────────────────────────────────────────

class EmpProfileApiService implements IEmpProfileService {
  EmpProfileApiService._();
  static final EmpProfileApiService instance = EmpProfileApiService._();

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    // TODO(backend): GET /employees/$employeeId/profile
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
  }) async {
    // TODO(backend): POST /employees/$employeeId/change-password
    throw UnimplementedError();
  }
}

// ── Factory ───────────────────────────────────────────────────────────────────

IEmpProfileService get empProfileService => AppConstants.useMockServices
    ? EmpProfileMockService.instance
    : EmpProfileApiService.instance;