import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import 'offer_repository.dart';

final _myOffersProvider = FutureProvider.autoDispose<List<Offer>>(
  (ref) => ref.read(offerRepositoryProvider).listMine(),
);

class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(_myOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(title: const Text('Minhas ofertas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/offers/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova oferta'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_myOffersProvider),
        child: offers.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.storefront_outlined,
                title: 'Nenhuma oferta publicada',
                subtitle: 'Publique produtos ou serviços para a rede.',
                actionLabel: 'Publicar primeira oferta',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _MyOfferCard(
                offer: items[i],
                onDeleted: () => ref.invalidate(_myOffersProvider),
              ),
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, __) => const _SkeletonCard(),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.textMuted, size: 40),
                const SizedBox(height: 12),
                Text('$e',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(_myOffersProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyOfferCard extends ConsumerWidget {
  const _MyOfferCard({required this.offer, required this.onDeleted});

  final Offer offer;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  kCurrency.format(offer.priceCents / 100.0),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (offer.category != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentWash,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      offer.category!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Arquivar oferta'),
                    content: const Text(
                        'A oferta será removida do marketplace.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.debit,
                          minimumSize: const Size(80, 40),
                        ),
                        child: const Text('Arquivar'),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                );
                if (ok == true) {
                  try {
                    await ref
                        .read(offerRepositoryProvider)
                        .delete(offer.id);
                    if (context.mounted) {
                      showAppSnackbar(context,
                          message: 'Oferta arquivada',
                          type: SnackbarType.success);
                      onDeleted();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showAppSnackbar(context,
                          message: 'Erro ao arquivar: $e',
                          type: SnackbarType.error);
                    }
                  }
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Arquivar')),
            ],
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted, size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Skeleton(width: 48, height: 48, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 14, width: 140),
                SizedBox(height: 8),
                Skeleton(height: 15, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
