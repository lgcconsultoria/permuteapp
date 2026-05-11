import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final TokenStorage _storage;
  final Dio _dio;
  bool _refreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.endsWith('/auth/refresh');

    if (!isUnauthorized || isRefreshCall || _refreshing) {
      return handler.next(err);
    }

    final refresh = await _storage.readRefresh();
    if (refresh == null) return handler.next(err);

    _refreshing = true;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final access = res.data?['accessToken'] as String?;
      final newRefresh = res.data?['refreshToken'] as String?;
      if (access == null || newRefresh == null) {
        await _storage.clear();
        return handler.next(err);
      }
      await _storage.save(accessToken: access, refreshToken: newRefresh);

      final retry = err.requestOptions
        ..headers['Authorization'] = 'Bearer $access';
      final response = await _dio.fetch<dynamic>(retry);
      return handler.resolve(response);
    } catch (_) {
      await _storage.clear();
      return handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
