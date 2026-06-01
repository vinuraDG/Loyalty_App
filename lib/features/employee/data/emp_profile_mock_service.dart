

import 'package:loyalty_app/features/employee/data/emp_profile_api_service.dart';

class EmpProfileMockService implements IEmpProfileService {
  EmpProfileMockService._();
  static final EmpProfileMockService instance = EmpProfileMockService._();

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    await _delay();
    return EmployeeProfileInfo(
      appVersion: '1.0.0',
      department: 'Human Resources',
      joinedDate: DateTime(2023, 1, 1),
    );
  }

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));
}