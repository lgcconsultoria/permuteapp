import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'offer_repository.dart';

final _offersProvider = FutureProvider.autoDispose<List<Offer>>(
  (ref) => ref.read(offerRepositoryProvider).list(),
);

class OfferListScreen extends ConsumerWidget {
  const OfferListScreen({super.key});

  static final _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'UP\$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(_offersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/offers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova oferta'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_offersProvider),
        child: offers.when(
          data: (items) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final o = items[i];
              return ListTile(
                title: Text(o.title),
                subtitle: Text('${o.companyName}\n${o.description}'),
                isThreeLine: true,
                trailing: Text(_currency.format(o.priceCents / 100.0)),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
        ),
      ),
    );
  }
}
