import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

/// Single entry point for every call to CdsTeam_Api.
///
/// Responsibilities:
///  * base URL from `--dart-define=API_BASE_URL`
///  * attach `Authorization: Bearer <token>` to everything except login
///  * on 401, clear the token and fire [onUnauthorized] so the app can route
///    back to the login screen from anywhere
///  * normalise every failure into an [ApiException] carrying the API's own
///    `error` message
class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio})
    : _tokenStore = tokenStore,
      // ignore: prefer_initializing_formals
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              // Let non-2xx flow into the error interceptor so 501 and 401
              // keep their bodies.
              validateStatus: (int? status) => status != null && status < 400,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );

    // Added last so it logs the final URL, after the auth header is attached.
    if (kDebugMode) {
      _dio.interceptors.add(_ApiLogger());
    }
  }

  final Dio _dio;
  final TokenStore _tokenStore;

  /// Invoked once whenever a 401 comes back from any endpoint.
  VoidCallback? onUnauthorized;

  Dio get raw => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool isPublic = AppConfig.unauthenticatedPaths.any(
      (String p) => options.path.startsWith(p),
    );

    if (!isPublic) {
      final String? token = await _tokenStore.read();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      final bool wasLoginAttempt = AppConfig.unauthenticatedPaths.any(
        (String p) => error.requestOptions.path.startsWith(p),
      );
      // A 401 from /login is "wrong password", not an expired session —
      // don't nuke state or bounce the user in that case.
      if (!wasLoginAttempt) {
        await _tokenStore.clear();
        onUnauthorized?.call();
      }
    }
    handler.next(error);
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send<T>(
    () => _dio.get<T>(path, queryParameters: query, cancelToken: cancelToken),
  );

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send<T>(
    () => _dio.post<T>(
      path,
      data: data,
      queryParameters: query,
      cancelToken: cancelToken,
    ),
  );

  /// A multipart `POST` (file uploads). Dio sets the correct
  /// `multipart/form-data; boundary=...` header itself whenever `data` is a
  /// [FormData], overriding the JSON default from [BaseOptions].
  Future<T> postFormData<T>(
    String path,
    FormData data, {
    CancelToken? cancelToken,
  }) =>
      _send<T>(() => _dio.post<T>(path, data: data, cancelToken: cancelToken));

  Future<T> put<T>(String path, {Object? data, CancelToken? cancelToken}) =>
      _send<T>(() => _dio.put<T>(path, data: data, cancelToken: cancelToken));

  Future<T> delete<T>(String path, {CancelToken? cancelToken}) =>
      _send<T>(() => _dio.delete<T>(path, cancelToken: cancelToken));

  Future<T> _send<T>(Future<Response<T>> Function() call) async {
    try {
      final Response<T> response = await call();
      return response.data as T;
    } on DioException catch (e) {
      if (!_isNetworkFailure(e)) throw ApiException.fromDio(e);
      // Couldn't even reach the host — swap to the other known base URL
      // (see AppConfig.apiFallbackBaseUrl) and give it one try before
      // giving up. Stays on whichever one works for the next call.
      _dio.options.baseUrl = _dio.options.baseUrl == AppConfig.apiBaseUrl
          ? AppConfig.apiFallbackBaseUrl
          : AppConfig.apiBaseUrl;
      try {
        final Response<T> response = await call();
        return response.data as T;
      } on DioException catch (e2) {
        throw ApiException.fromDio(e2);
      }
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  static bool _isNetworkFailure(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.unknown;

  /// GET returning raw bytes (e.g. `application/pdf`).
  Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send<Uint8List>(
    () => _dio.get<Uint8List>(
      path,
      queryParameters: query,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes),
    ),
  );

  /// GET returning a JSON array, normalised to `List<Map<String, dynamic>>`.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    final dynamic data = await get<dynamic>(
      path,
      query: query,
      cancelToken: cancelToken,
    );
    if (data is List) {
      return data
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}

/// Debug-only: prints one block per call once it finishes — the URL, the
/// request headers (including the bearer token), the request body and the
/// response body together, for successes and errors alike. The login
/// password is still masked.
class _ApiLogger extends Interceptor {
  static const int _maxBody = 4000;
  static const JsonEncoder _json = JsonEncoder.withIndent('  ');

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      title: '✓ SUCCESS ${response.statusCode}',
      options: response.requestOptions,
      responseBody: response.data,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Response<dynamic>? response = err.response;
    final String status = response?.statusCode?.toString() ?? err.type.name;
    _log(
      title: '✗ ERROR $status',
      options: err.requestOptions,
      responseBody: response?.data,
      reason: response?.statusMessage ?? err.message,
    );
    handler.next(err);
  }

  void _log({
    required String title,
    required RequestOptions options,
    required Object? responseBody,
    String? reason,
  }) {
    final StringBuffer out = StringBuffer()
      ..writeln('[api] ┌── $title ─────────────────────────')
      ..writeln('[api] │ ${options.method} ${options.uri}');
    if (reason != null && reason.isNotEmpty) {
      out.writeln('[api] │ reason: $reason');
    }
    out.writeln('[api] │ request headers:');
    options.headers.forEach((String key, dynamic value) {
      out.writeln('[api] │   $key: $value');
    });
    out
      ..writeln('[api] │ request body:')
      ..writeln(_indent(_format(options.data)))
      ..writeln('[api] │ response body:')
      ..writeln(_indent(_format(responseBody)))
      ..write('[api] └──────────────────────────────────────');

    // wrapWidth keeps logcat from silently truncating long bodies.
    debugPrint(out.toString(), wrapWidth: 1024);
  }

  static String _indent(String text) =>
      text.split('\n').map((String line) => '[api] │   $line').join('\n');

  static String _format(Object? body) {
    if (body == null || body.toString().isEmpty) return '(none)';
    if (body is List<int>) return '(${body.length} bytes)';

    Object safe = body;
    if (body is Map && body.containsKey('password')) {
      safe = <dynamic, dynamic>{...body, 'password': '***'};
    }

    String text;
    try {
      text = _json.convert(safe);
    } catch (_) {
      text = safe.toString();
    }

    return text.length > _maxBody
        ? '${text.substring(0, _maxBody)}… (${text.length} chars total)'
        : text;
  }
}
