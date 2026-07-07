// lib/features/employee/profile/data/emp_profile_api_service.dart

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'emp_profile_mock_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class EmployeeProfileInfo {
  final String phone;
  final String title;
  final String firstName;
  final String lastName;
  final String email;

  const EmployeeProfileInfo({
    required this.phone,
    required this.title,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  factory EmployeeProfileInfo.fromJson(Map<String, dynamic> json) =>
      EmployeeProfileInfo(
        phone:     (json['PhoneNo']    ?? json['phoneNo']    ?? json['phone'] ?? '').toString(),
        title:     (json['Title']      ?? json['title']      ?? 'Staff Member').toString(),
        firstName: (json['FirstName']  ?? json['firstName']  ?? '').toString(),
        lastName:  (json['LastName']   ?? json['lastName']   ?? '').toString(),
        email:     (json['Email']      ?? json['email']      ?? '').toString(),
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

// ── Real API service ──────────────────────────────────────────────────────────

class EmpProfileApiService implements IEmpProfileService {
  EmpProfileApiService._();
  static final EmpProfileApiService instance = EmpProfileApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      final res = await _dio.get(
        'Common/GetEmployeeByPhoneNo',
        queryParameters: {'EmployeePhoneNo': phone},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return EmployeeProfileInfo.fromJson(data);
      }
    } on DioException catch (_) {
      // fall through to fallback
    }
    return EmployeeProfileInfo(phone: phone, title: 'Staff Member');
  }

  @override
  Future<void> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      await _dio.post(
        'Common/ResetPassword',
        options: Options(responseType: ResponseType.plain),
        data: {
          'UserName':        phone,
          'Password':        currentPassword,
          'NewPassword':     newPassword,
          'ConfirmPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        msg = (data['message'] ?? data['Message'] ?? data['error'])?.toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      throw Exception(msg ?? 'Failed to change password. Please try again.');
    }
  }
}

// ── Factory ───────────────────────────────────────────────────────────────────

IEmpProfileService get empProfileService => AppConstants.useMockServices
    ? EmpProfileMockService.instance
    : EmpProfileApiService.instance;
