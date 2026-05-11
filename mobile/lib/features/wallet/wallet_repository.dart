import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

class WalletBalance {
  WalletBalance({required this.walletId, required this.balanceCents});

  final String walletId;
  final int balanceCents;

  double get reais => balanceCents / 100.0;
}

class StatementEntry {
  StatementEntry({
    required this.id,
    required this.kind,
    required this.amountCents,
    required this.balanceAfter,
    required this.type,
    required this.createdAt,
    this.description,
    this.counterpartyName,
  });

  factory StatementEntry.fromJson(Map<String, dynamic> json) {
    final cp = json['counterparty'] as Map<String, dynamic>?;
    return StatementEntry(
      id: json['id'] as String,
      kind: json['kind'] as String,
      amountCents: json['amountCents'] as int,
      balanceAfter: json['balanceAfter'] as int,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      counterpartyName:
          cp == null ? null : (cp['nomeFantasia'] ?? cp['razaoSocial']) as String?,
    );
  }

  final String id;
  final String kind;
  final int amountCents;
  final int balanceAfter;
  final String type;
  final String? description;
  final String? counterpartyName;
  final DateTime createdAt;

  bool get isCredit => kind == 'CREDIT';
}

class WalletRepository {
  WalletRepository(this._dio);
  final Dio _dio;

  Future<WalletBalance> balance() async {
    final res = await _dio.get<Map<String, dynamic>>('/wallet/balance');
    return WalletBalance(
      walletId: res.data!['walletId'] as String,
      balanceCents: res.data!['balanceCents'] as int,
    );
  }

  Future<List<StatementEntry>> statement({int limit = 50}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/wallet/statement',
      queryParameters: {'limit': limit},
    );
    final items = res.data!['items'] as List<dynamic>;
    return items
        .map((e) => StatementEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> transfer({
    required String toCompanyId,
    required int amountCents,
    String? description,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/transactions/transfer',
      data: {
        'toCompanyId': toCompanyId,
        'amountCents': amountCents,
        if (description != null) 'description': description,
      },
    );
    return res.data!;
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.read(apiClientProvider)),
);
