import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'wallet_repository.dart';

final _balanceProvider = FutureProvider.autoDispose<WalletBalance>(
  (ref) => ref.read(walletRepositoryProvider).balance(),
);

final _statementProvider = FutureProvider.autoDispose<List<StatementEntry>>(
  (ref) => ref.read(walletRepositoryProvider).statement(),
);

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  static final _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'UP\$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(_balanceProvider);
    final statement = ref.watch(_statementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carteira')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_balanceProvider);
          ref.invalidate(_statementProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: balance.when(
                  data: (b) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo disponível'),
                      const SizedBox(height: 8),
                      Text(
                        _currency.format(b.reais),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Erro: $e'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Extrato', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            statement.when(
              data: (entries) => Column(
                children: entries.map(_StatementTile.new).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementTile extends StatelessWidget {
  const _StatementTile(this.entry);

  final StatementEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.isCredit ? Colors.green : Colors.red;
    final sign = entry.isCredit ? '+' : '-';
    final amount = WalletScreen._currency.format(entry.amountCents / 100.0);
    final subtitle = [
      entry.counterpartyName ?? entry.type,
      if (entry.description != null) entry.description!,
    ].join(' • ');

    return ListTile(
      leading: Icon(
        entry.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
        color: color,
      ),
      title: Text('$sign $amount', style: TextStyle(color: color)),
      subtitle: Text(subtitle),
      trailing: Text(
        DateFormat('dd/MM HH:mm').format(entry.createdAt.toLocal()),
      ),
    );
  }
}
