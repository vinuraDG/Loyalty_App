// lib/features/employee/data/emp_profile_mock_service.dart
//
// Mock implementation of IEmpProfileService.
// All data is sourced from lib/data/mock_data.dart — no data lives here.
// Swap to EmpProfileApiService.instance when the backend is ready.

import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/employee/data/emp_profile_api_service.dart';

class EmpProfileMockService implements IEmpProfileService {
  EmpProfileMockService._();
  static final EmpProfileMockService instance = EmpProfileMockService._();

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    await _delay();
    final raw = kMockEmployeeProfiles[employeeId] as Map<String, dynamic>?;
    // Fall back to safe defaults if the employeeId has no profile entry.
    final data = raw ??
        const {
          'phone': '—',
          'title': 'Staff Member',
        };
    return EmployeeProfileInfo.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _delay(ms: 600);
    // Validate against the mock password store.
    final stored = kMockPasswords[employeeId];
    if (stored == null || stored != currentPassword) {
      throw Exception('Current password is incorrect.');
    }
    // In mock mode there is no persistent store, so we simply succeed.
  }

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));
}