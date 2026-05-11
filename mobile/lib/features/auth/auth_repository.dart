import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<void> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    await _persist(res.data!);
  }

  Future<void> register({
    required String cnpj,
    required String razaoSocial,
    String? nomeFantasia,
    required String email,
    String? phone,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'cnpj': cnpj,
        'razaoSocial': razaoSocial,
        if (nomeFantasia != null) 'nomeFantasia': nomeFantasia,
        'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      },
    );
    await _persist(res.data!);
  }

  Future<void> logout() async {
    final refresh = await _storage.readRefresh();
    if (refresh != null) {
      try {
        await _dio.post<void>('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {
        // ignore: best-effort logout
      }
    }
    await _storage.clear();
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    await _storage.save(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.read(apiClientProvider),
    ref.read(tokenStorageProvider),
  ),
);
