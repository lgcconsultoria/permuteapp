import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import 'wallet_repository.dart';

final _balanceProvider = FutureProvider.autoDispose<WalletBalance>(
  (ref) => ref.read(walletRepositoryProvider).balance(),
);

final _statementProvider = FutureProvider.autoDispose<List<StatementEntry>>(
  (ref) => ref.read(walletRepositoryProvider).statement(),
);

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(_balanceProvider);
    final statement = ref.watch(_statementProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_balanceProvider);
          ref.invalidate(_statementProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _BalanceCard(balance: balance),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Extrato',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: statement.whenOrNull(
                            data: (entries) => Text(
                              '${entries.length} movimentos',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ) ??
                          const Text('…',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            _StatementSliver(statement: statement),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ─── Balance Card ────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final AsyncValue<WalletBalance> balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.walletGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Carteira · UP\$',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/transfer'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Transferir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Saldo disponível',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            balance.when(
              data: (b) => Text(
                kCurrency.format(b.reais),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              loading: () =>
                  const Skeleton(width: 160, height: 40, radius: 8),
              error: (_, __) => const Text('—',
                  style: TextStyle(color: Colors.white, fontSize: 36)),
            ),
            const SizedBox(height: 4),
            const Text(
              '1 UP\$ equivale a R\$ 1,00',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Statement Sliver ────────────────────────────────────────────────────────

class _StatementSliver extends StatelessWidget {
  const _StatementSliver({required this.statement});

  final AsyncValue<List<StatementEntry>> statement;

  @override
  Widget build(BuildContext context) {
    return statement.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sem movimentações',
              subtitle: 'Suas transações vão aparecer aqui.',
            ),
          );
        }

        // Agrupar por data
        final grouped = <String, List<StatementEntry>>{};
        for (final e in entries) {
          final key = formatRelativeDate(e.createdAt);
          grouped.putIfAbsent(key, () => []).add(e);
        }

        final sections = grouped.entries.toList();
        final items = <(bool isHeader, Object data)>[];
        for (final section in sections) {
          items.add((true, section.key));
          for (final entry in section.value) {
            items.add((false, entry));
          }
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final item = items[i];
              if (item.$1) {
                return _DateHeader(label: item.$2 as String);
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: _StatementRow(entry: item.$2 as StatementEntry),
              );
            },
            childCount: items.length,
          ),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _StatementRowSkeleton(),
          ),
          childCount: 6,
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
            child: Text('Erro ao carregar extrato: $e',
                style:
                    const TextStyle(color: AppColors.textSecondary))),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({required this.entry});

  final StatementEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit;
    final color = isCredit ? AppColors.credit : AppColors.debit;
    final bgColor =
        isCredit ? AppColors.credit.withOpacity(0.08) : AppColors.debit.withOpacity(0.08);
    final sign = isCredit ? '+' : '−';
    final amount = kCurrency.format(entry.amountCents / 100.0);
    final subtitle =
        entry.counterpartyName ?? _typeLabel(entry.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.description != null)
                  Text(
                    entry.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign $amount',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(entry.createdAt.toLocal()),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'TRANSFER' => 'Transferência',
      'OFFER_PAYMENT' => 'Pagamento de oferta',
      'ADJUSTMENT' => 'Ajuste',
      _ => type,
    };
  }
}

class _StatementRowSkeleton extends StatelessWidget {
  const _StatementRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Skeleton(width: 40, height: 40, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 110, height: 14),
                SizedBox(height: 6),
                Skeleton(width: 70, height: 11),
              ],
            ),
          ),
          SizedBox(width: 12),
          Skeleton(width: 70, height: 14),
        ],
      ),
    );
  }
}
