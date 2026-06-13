import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/customer/qr/data/qr_mock_service.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IQrService {
  Future<String> getQrPayload(String userId, String userName);
}

// ── Real API service ──────────────────────────────────────────────────────────

class QrApiService implements IQrService {
  QrApiService._();
  static final QrApiService instance = QrApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<String> getQrPayload(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      // QR payload = phone number encoded — employee scans to identify customer
      // Backend can later return a signed token from a dedicated endpoint
      final res = await _dio.get('Common/GetCustomerByPhoneNo',
          queryParameters: {'PhoneNo': phone});
      final data = (res.data['customer'] ?? res.data['data'] ?? res.data)
          as Map<String, dynamic>;
      return jsonEncode({
        'userId': userId,
        'phone': phone,
        'name': userName,
        'customerId': (data['Id'] ?? data['CustomerId'] ?? userId).toString(),
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } on DioException catch (_) {
      // Fallback: encode phone directly — always scannable
      return jsonEncode({
        'userId': userId,
        'phone': phone,
        'name': userName,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}

// ── Service factory ───────────────────────────────────────────────────────────

IQrService get qrService => AppConstants.useMockServices
    ? QrMockService.instance
    : QrApiService.instance;