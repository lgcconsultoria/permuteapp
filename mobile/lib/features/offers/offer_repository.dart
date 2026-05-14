import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

class Offer {
  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.companyName,
    this.category,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>?;
    return Offer(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priceCents: int.parse(json['priceCents'].toString()),
      category: json['category'] as String?,
      companyName: (company?['nomeFantasia'] ?? company?['razaoSocial'] ?? '')
          as String,
    );
  }

  final String id;
  final String title;
  final String description;
  final int priceCents;
  final String? category;
  final String companyName;
}

class OfferRepository {
  OfferRepository(this._dio);
  final Dio _dio;

  Future<List<Offer>> list({String? query, String? category}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/offers',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final items = res.data!['items'] as List<dynamic>;
    return items.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Offer>> listMine() async {
    final res = await _dio.get<List<dynamic>>('/offers/mine');
    return (res.data ?? [])
        .map((e) => Offer.fromJson({
              ...(e as Map<String, dynamic>),
              'company': null,
            }))
        .toList();
  }

  Future<Offer> create({
    required String title,
    required String description,
    required int priceCents,
    String? category,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/offers',
      data: {
        'title': title,
        'description': description,
        'priceCents': priceCents,
        if (category != null) 'category': category,
      },
    );
    return Offer.fromJson({...res.data!, 'company': null});
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/offers/$id');
  }
}

final offerRepositoryProvider = Provider<OfferRepository>(
  (ref) => OfferRepository(ref.read(apiClientProvider)),
);
