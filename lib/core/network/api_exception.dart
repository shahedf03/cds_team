import 'dart:convert';

import 'package:dio/dio.dart';

/// Every error body from CdsTeam_Api is `{ "error": "human readable message" }`.
/// This wraps it so screens can surface `message` directly instead of a
/// generic "something went wrong".
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetworkError;

  /// Bad or expired token — the caller should be routed back to login.
  bool get isUnauthorized => statusCode == 401;

  /// Bad input — show [message] against the offending field.
  bool get isBadRequest => statusCode == 400;

  /// Endpoint exists but the backend hasn't enabled it yet (see §10).
  /// Screens should render a "Coming soon" state, not an error.
  bool get isNotImplemented => statusCode == 501;

  /// Unexpected server fault — generic retry message.
  bool get isServerError =>
      statusCode != null && statusCode! >= 500 && statusCode != 501;

  factory ApiException.fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: 'The server took too long to respond. Please try again.',
        isNetworkError: true,
      );
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return ApiException(
        message:
            'Cannot reach the server. Check your connection and try again.',
        isNetworkError: true,
      );
    }

    if (e.type == DioExceptionType.cancel) {
      return ApiException(message: 'Request cancelled.');
    }

    final int? status = e.response?.statusCode;
    return ApiException(
      message: _readErrorBody(e.response?.data) ?? _fallbackFor(status),
      statusCode: status,
    );
  }

  /// Pulls `error` out of the response body, whatever shape it arrives in.
  ///
  /// Two shapes come back: our own `{ "error": ... }`, and ASP.NET Core's
  /// automatic request validation (`application/problem+json`, with `title`
  /// and an `errors` map of field → messages), which short-circuits before
  /// the API's own code runs.
  static String? _readErrorBody(dynamic data) {
    if (data == null) return null;
    // Byte responses (the PDF report) carry their error JSON as raw bytes.
    if (data is List<int>) {
      try {
        return _readErrorBody(jsonDecode(utf8.decode(data)));
      } catch (_) {
        return null;
      }
    }
    if (data is Map) {
      final dynamic error = data['error'] ?? data['Error'] ?? data['message'];
      if (error is String && error.trim().isNotEmpty) return error.trim();

      final dynamic errors = data['errors'];
      if (errors is Map) {
        for (final dynamic messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            return messages.first.toString();
          }
          if (messages is String && messages.trim().isNotEmpty) {
            return messages.trim();
          }
        }
      }

      final dynamic title = data['title'];
      if (title is String && title.trim().isNotEmpty) return title.trim();
    }
    if (data is String && data.trim().isNotEmpty && data.length < 300) {
      return data.trim();
    }
    return null;
  }

  static String _fallbackFor(int? status) {
    switch (status) {
      case 400:
        return 'The request was rejected. Please check the values and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
        return 'That record no longer exists.';
      case 501:
        return 'This feature is not available yet.';
      default:
        return 'Something went wrong on the server. Please try again.';
    }
  }

  @override
  String toString() => message;
}
