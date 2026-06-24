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

// ── Real API service ──────────────────────────────────────────────────────────

class EmpProfileApiService implements IEmpProfileService {
  EmpProfileApiService._();
  static final EmpProfileApiService instance = EmpProfileApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<EmployeeProfileInfo> getProfileInfo(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
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
      await _dio.post('Common/ResetPassword', data: {
        'UserName':        phone,
        'OldPassword':     currentPassword,
        'NewPassword':     newPassword,
        'ConfirmPassword': newPassword,
      });
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
