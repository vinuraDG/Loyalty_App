// lib/features/employee/profile/data/emp_profile_mock_service.dart

import 'package:loyalty_app/data/mock_data.dart';
import 'emp_profile_api_service.dart';

class EmpProfileMockService implements IEmpProfileService {
  EmpProfileMockService._();
  static final EmpProfileMockService instance = EmpProfileMockService._();

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    await _delay();
    final raw = kMockEmployeeProfiles[employeeId] as Map<String, dynamic>?;
    return EmployeeProfileInfo.fromJson(
      raw ?? const {'phone': '—', 'title': 'Staff Member'},
    );
  }

  @override
  Future<void> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _delay(ms: 600);
    final stored = kMockPasswords[employeeId];
    if (stored == null || stored != currentPassword) {
      throw Exception('Current password is incorrect.');
    }
    // Mock: succeeds silently
  }

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));
}