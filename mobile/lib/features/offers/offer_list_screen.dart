import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import 'offer_repository.dart';

// Estado de busca/filtro
class _FilterState {
  const _FilterState({this.query = '', this.category});
  final String query;
  final String? category;

  _FilterState copyWith({String? query, String? category, bool clearCategory = false}) {
    return _FilterState(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

final _filterProvider =
    StateProvider.autoDispose<_FilterState>((_) => const _FilterState());

final _offersProvider = FutureProvider.autoDispose<List<Offer>>((ref) {
  final filter = ref.watch(_filterProvider);
  return ref.read(offerRepositoryProvider).list(
        query: filter.query.isEmpty ? null : filter.query,
        category: filter.category,
      );
});

const _categories = [
  'Alimentação',
  'Hospedagem',
  'Logística',
  'Marketing',
  'Tecnologia',
  'Saúde',
  'Educação',
  'Serviços',
];

class OfferListScreen extends ConsumerStatefulWidget {
  const OfferListScreen({super.key});

  @override
  ConsumerState<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends ConsumerState<OfferListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_filterProvider);
    final offers = ref.watch(_offersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/offers/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova oferta'),
        elevation: 2,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar + busca
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Marketplace',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Produtos e serviços disponíveis na rede',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => ref
                          .read(_filterProvider.notifier)
                          .state = filter.copyWith(query: v),
                      onSubmitted: (v) =>
                          ref.invalidate(_offersProvider),
                      decoration: InputDecoration(
                        hintText: 'Buscar ofertas…',
                        prefixIcon:
                            const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: filter.query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref
                                      .read(_filterProvider.notifier)
                                      .state = filter.copyWith(query: '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chips de categoria
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'Todas',
                      selected: filter.category == null,
                      onTap: () => ref
                          .read(_filterProvider.notifier)
                          .state = filter.copyWith(clearCategory: true),
                    ),
                    ..._categories.map(
                      (c) => _CategoryChip(
                        label: c,
                        selected: filter.category == c,
                        onTap: () => ref
                            .read(_filterProvider.notifier)
                            .state = filter.copyWith(
                            category: filter.category == c ? null : c,
                            clearCategory: filter.category == c,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contador de resultados
            SliverToBoxAdapter(
              child: offers.whenOrNull(
                    data: (items) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text(
                        '${items.length} ${items.length == 1 ? 'oferta encontrada' : 'ofertas encontradas'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ) ??
                  const SizedBox.shrink(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Lista
            offers.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Nenhuma oferta encontrada',
                      subtitle:
                          'Tente mudar o filtro ou seja o primeiro a publicar.',
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _OfferCard(offer: items[i]),
                    ),
                    childCount: items.length,
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _OfferCardSkeleton(),
                  ),
                  childCount: 5,
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('$e',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(_offersProvider),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
        showCheckmark: false,
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.primary, size: 26),
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
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.companyName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  offer.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (offer.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentWash,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          offer.category!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      kCurrency.format(offer.priceCents / 100.0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCardSkeleton extends StatelessWidget {
  const _OfferCardSkeleton();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 56, height: 56, radius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 15),
                SizedBox(height: 8),
                Skeleton(width: 100, height: 12),
                SizedBox(height: 8),
                Skeleton(height: 12),
                SizedBox(height: 6),
                Skeleton(width: 160, height: 12),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Skeleton(width: 60, height: 20, radius: 20),
                    Skeleton(width: 80, height: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
