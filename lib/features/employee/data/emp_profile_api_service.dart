import 'package:loyalty_app/data/mock_data.dart';

class EmployeeProfileInfo {
  final String appVersion;
  final String department;
  final DateTime joinedDate;

  const EmployeeProfileInfo({
    required this.appVersion,
    required this.department,
    required this.joinedDate,
  });
}

abstract class IEmpProfileService {
  /// Extra profile info shown on the employee profile page.
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId);
}

class EmpProfileApiService implements IEmpProfileService {
  EmpProfileApiService._();
  static final EmpProfileApiService instance = EmpProfileApiService._();

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/profile
    // expect → { "appVersion": "1.0.0", "department": "Fuel Station", "joinedDate": "2024-01-10" }
    throw UnimplementedError(
        'Backend not connected yet: GET $kBaseUrl/employees/$employeeId/profile');
  }
}