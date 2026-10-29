import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// HTTP client for the 360 backend.
///
/// Mirrors frontend/src/services/lib/axios.ts:
/// - attaches `Authorization: Bearer <access token>`
/// - on an auth failure, refreshes once with `POST /auth/refresh` (serialised
///   so concurrent requests share one refresh) and retries the request
/// - clears the session and notifies [onSessionExpired] when refresh fails
///
/// Unlike the web app we also refresh when the access token is about to expire
/// and we treat a 403 with an expired token as an auth failure, because the
/// backend's JwtAuthenticationFilter silently drops invalid tokens and Spring
/// then answers 403 for anonymous callers.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
        validateStatus: (_) => true,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshing;

  /// Called when the refresh token is rejected; the auth controller signs out.
  void Function()? onSessionExpired;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasSession => _refreshToken != null && _refreshToken!.isNotEmpty;

  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // ---------------------------------------------------------------------------
  // Public helpers
  // ---------------------------------------------------------------------------

  /// GET and return the unwrapped `payload`.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('POST', path, body: body, query: query, auth: auth);

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('PUT', path, body: body, query: query, auth: auth);

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('PATCH', path, body: body, query: query, auth: auth);

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('DELETE', path, body: body, query: query, auth: auth);

  /// Multipart upload (profile image, product image).
  Future<dynamic> upload(
    String path,
    FormData form, {
    String method = 'POST',
  }) =>
      _send(method, path, body: form, auth: true);

  /// Fetch raw bytes with the bearer token (image preview endpoint requires
  /// `file:read`, so a plain Image.network cannot load it).
  Future<Uint8List?> getBytes(String path, {Map<String, dynamic>? query}) async {
    if (_accessToken != null && _isExpiring(_accessToken!)) {
      await _refresh();
    }
    try {
      final response = await _dio.get<List<int>>(
        '${AppConfig.baseUrl}$path',
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          extra: {'auth': true},
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required bool auth,
    bool retried = false,
  }) async {
    if (auth && _accessToken != null && _isExpiring(_accessToken!)) {
      await _refresh();
    }

    final cleanQuery = <String, dynamic>{};
    query?.forEach((key, value) {
      if (value == null) return;
      final text = value.toString();
      if (text.isEmpty) return;
      cleanQuery[key] = text;
    });

    Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        '${AppConfig.baseUrl}$path',
        data: body,
        queryParameters: cleanQuery,
        options: Options(
          method: method,
          extra: {'auth': auth},
          contentType: body is FormData ? 'multipart/form-data' : null,
        ),
      );
    } on DioException catch (e) {
      throw _mapNetworkError(e);
    }

    final status = response.statusCode ?? 0;
    final isAuthFailure = status == 401 ||
        (status == 403 &&
            auth &&
            (_accessToken == null || _isExpiring(_accessToken!)));

    if (auth && isAuthFailure && !retried && hasSession) {
      final ok = await _refresh();
      if (ok) {
        return _send(method, path,
            body: body, query: query, auth: auth, retried: true);
      }
      throw ApiException(message: 'Session expired', statusCode: 401);
    }

    if (status >= 200 && status < 300) {
      return _unwrap(response.data);
    }
    throw _mapHttpError(status, response.data);
  }

  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final needsAuth = options.extra['auth'] as bool? ?? true;
    if (needsAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('payload')) return data['payload'];
      if (data.containsKey('success') && data['success'] == false) {
        throw ApiException(
          message: data['message']?.toString() ?? 'Request failed',
          statusCode: _statusFromBody(data['status']),
        );
      }
    }
    return data;
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  Future<bool> _refresh() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight;
    final future = _doRefresh();
    _refreshing = future;
    return future.whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final token = _refreshToken;
    if (token == null || token.isEmpty) {
      _expire();
      return false;
    }
    try {
      final response = await _dio.post<dynamic>(
        '${AppConfig.baseUrl}/auth/refresh',
        data: {'refreshToken': token},
        options: Options(extra: {'auth': false}),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        _expire();
        return false;
      }
      final data = response.data;
      final payload = data is Map<String, dynamic>
          ? (data['payload'] ?? data['data'] ?? data)
          : null;
      if (payload is! Map<String, dynamic>) {
        _expire();
        return false;
      }
      final newAccess = payload['accessToken']?.toString();
      final newRefresh = payload['refreshToken']?.toString() ?? token;
      if (newAccess == null || newAccess.isEmpty) {
        _expire();
        return false;
      }
      _accessToken = newAccess;
      _refreshToken = newRefresh;
      await TokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } on DioException {
      // Network error during refresh: keep the session so the user can retry.
      return false;
    }
  }

  void _expire() {
    clearTokens();
    onSessionExpired?.call();
  }

  /// True when the JWT `exp` claim is within 30 seconds of now (or unreadable).
  bool _isExpiring(String jwt) {
    final exp = jwtExpiry(jwt);
    if (exp == null) return false;
    return DateTime.now().isAfter(exp.subtract(const Duration(seconds: 30)));
  }

  static DateTime? jwtExpiry(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  ApiException _mapNetworkError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: 'The server took too long to respond. Please try again.',
        isNetwork: true,
      );
    }
    if (e.error is SocketException || e.type == DioExceptionType.connectionError) {
      return ApiException(
        message:
            'Cannot reach the server at ${AppConfig.baseUrl}. Check your connection or the server address.',
        isNetwork: true,
      );
    }
    if (kDebugMode) debugPrint('Dio error: ${e.type} ${e.message}');
    return ApiException(message: e.message ?? 'Network error', isNetwork: true);
  }

  ApiException _mapHttpError(int status, dynamic body) {
    String message;
    final fields = <String, String>{};

    if (body is Map<String, dynamic>) {
      if (body['message'] != null) {
        message = body['message'].toString();
        if (body['detail'] != null) {
          message = '$message: ${body['detail']}';
        }
      } else if (body['error'] != null) {
        message = body['error'].toString();
      } else {
        // Bean validation shape: {field: message}
        body.forEach((k, v) {
          if (v is String) fields[k] = v;
        });
        message = fields.isNotEmpty
            ? fields.values.join('\n')
            : 'Request failed ($status)';
      }
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.length > 200 ? body.substring(0, 200) : body;
    } else {
      message = switch (status) {
        400 => 'Invalid request',
        401 => 'Please sign in again',
        403 => 'You do not have permission to do this',
        404 => 'Not found',
        409 => 'This record already exists',
        500 => 'Server error, please try again',
        _ => 'Request failed ($status)',
      };
    }

    if (status == 403 && fields.isEmpty && message.startsWith('Request failed')) {
      message = 'You do not have permission to do this';
    }

    return ApiException(message: message, statusCode: status, fieldErrors: fields);
  }

  int? _statusFromBody(dynamic status) {
    if (status is num) return status.toInt();
    if (status is String) {
      return switch (status) {
        'BAD_REQUEST' => 400,
        'UNAUTHORIZED' => 401,
        'FORBIDDEN' => 403,
        'NOT_FOUND' => 404,
        'CONFLICT' => 409,
        _ => null,
      };
    }
    return null;
  }
}
