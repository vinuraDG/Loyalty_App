// lib/features/employee/data/emp_profile_api_service.dart
//
// Defines the data models and service interface for the employee profile
// feature. The real implementation (EmpProfileApiService) hits the backend;
// the mock implementation (EmpProfileMockService) uses local data.

// ── Data models ───────────────────────────────────────────────────────────────

class EmployeeProfileInfo {
  final String phone;
  final String title;

  const EmployeeProfileInfo({
    required this.phone,
    required this.title,
  });

  factory EmployeeProfileInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeProfileInfo(
      phone: json['phone'] as String? ?? '—',
      title: json['title'] as String? ?? 'Staff Member',
    );
  }
}

// ── Service interface ─────────────────────────────────────────────────────────

abstract class IEmpProfileService {
  /// Returns extra profile info for the given employee.
  /// Throws on network / server error.
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId);

  /// Changes the employee's password.
  /// Throws [Exception] with a human-readable message on failure
  /// (wrong current password, network error, etc.).
  Future<void> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
  });
}

// ── Real API implementation (stub — fill in when backend is ready) ────────────

class EmpProfileApiService implements IEmpProfileService {
  EmpProfileApiService._();
  static final EmpProfileApiService instance = EmpProfileApiService._();

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    // TODO: replace with real HTTP call, e.g.:
    // final res = await http.get(Uri.parse('$kBaseUrl/employees/$employeeId/profile'));
    // return EmployeeProfileInfo.fromJson(jsonDecode(res.body));
    throw UnimplementedError('EmpProfileApiService.getProfileInfo');
  }

  @override
  Future<void> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
  }) async {
    // TODO: replace with real HTTP call, e.g.:
    // await http.post(Uri.parse('$kBaseUrl/employees/$employeeId/change-password'), ...);
    throw UnimplementedError('EmpProfileApiService.changePassword');
  }
}