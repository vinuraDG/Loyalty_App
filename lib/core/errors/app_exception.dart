import 'package:dio/dio.dart';

/// Converts a [DioException] into a human-readable message.
String dioErrorMessage(DioException e) {
  final data = e.response?.data;
  String? serverMsg;
  if (data is Map) {
    serverMsg =
        (data['message'] ?? data['Message'] ?? data['error'])?.toString();
  } else if (data is String && data.isNotEmpty) {
    serverMsg = data;
  }
  if (serverMsg != null && serverMsg.trim().isNotEmpty) return serverMsg.trim();

  switch (e.response?.statusCode) {
    case 400: return 'Invalid request. Please check your input.';
    case 401: return 'Session expired. Please log in again.';
    case 403: return 'Access denied.';
    case 404: return 'The requested data was not found.';
    case 409: return 'A conflict occurred. The record may already exist.';
    case 422: return 'Validation failed. Please check your input.';
    case 500: return 'Server error. Please try again later.';
    case 503: return 'Service unavailable. Please try again later.';
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Request timed out. Check your network connection.';
    case DioExceptionType.connectionError:
      return 'Cannot reach the server. Check your internet connection.';
    case DioExceptionType.cancel:
      return 'Request was cancelled.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
