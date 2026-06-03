// lib/features/employee/data/emp_profile_api_service.dart
//
// Contains:
//   • EmployeeProfileInfo    — extra info shown on the profile page
//   • IEmpProfileService     — interface both mock and real services implement
//   • EmpProfileApiService   — real backend stubs (fill in TODOs when ready)
//
// ─── How to go live ───────────────────────────────────────────────────────────
// 1. Set kBaseUrl in lib/data/mock_data.dart.
// 2. Fill in the TODO below.
// 3. In employee_profile_page.dart swap:
//      final _svc = EmpProfileMockService.instance;  // ← remove
//      final _svc = EmpProfileApiService.instance;   // ← add
// ─────────────────────────────────────────────────────────────────────────────

import 'package:loyalty_app/data/mock_data.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class EmployeeProfileInfo {
  final String phone;
  final String title;

  const EmployeeProfileInfo({
    required this.phone,
    required this.title,
  });

  factory EmployeeProfileInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeProfileInfo(
      phone: json['phone'] as String,
      title: json['title'] as String,
    );
  }
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IEmpProfileService {
  /// Extra profile data displayed on the employee profile page.
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId);
}

// ── Real API service (stubs) ──────────────────────────────────────────────────

class EmpProfileApiService implements IEmpProfileService {
  EmpProfileApiService._();
  static final EmpProfileApiService instance = EmpProfileApiService._();

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/profile
    // Headers → { "Authorization": "Bearer <token>" }
    // 200 → { "phone": "0779876543", "title": "Senior Attendant" }
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/profile');
  }
}