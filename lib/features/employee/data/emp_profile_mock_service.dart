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
          'appVersion': '1.0.0',
          'department': 'General',
          'joinedDate': '2024-01-01',
        };
    return EmployeeProfileInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));
}