import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.razaoSocial,
    required this.email,
    this.nomeFantasia,
    this.phone,
    this.cnpj,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) =>
      CompanyProfile(
        id: json['id'] as String,
        razaoSocial: json['razaoSocial'] as String,
        email: json['email'] as String,
        nomeFantasia: json['nomeFantasia'] as String?,
        phone: json['phone'] as String?,
        cnpj: json['cnpj'] as String?,
      );

  final String id;
  final String razaoSocial;
  final String email;
  final String? nomeFantasia;
  final String? phone;
  final String? cnpj;

  String get displayName => nomeFantasia ?? razaoSocial;

  String get initials {
    final name = displayName;
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class ProfileRepository {
  ProfileRepository(this._dio);
  final Dio _dio;

  Future<CompanyProfile> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/companies/me');
    return CompanyProfile.fromJson(res.data!);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(apiClientProvider)),
);

final profileProvider = FutureProvider.autoDispose<CompanyProfile>(
  (ref) => ref.read(profileRepositoryProvider).me(),
);
