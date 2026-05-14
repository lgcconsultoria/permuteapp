import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/utils/formatters.dart';
import '../offers/offer_repository.dart';
import '../profile/profile_repository.dart';
import '../wallet/wallet_repository.dart';

final _homeBalanceProvider = FutureProvider.autoDispose<WalletBalance>(
  (ref) => ref.read(walletRepositoryProvider).balance(),
);

final _homeOffersProvider = FutureProvider.autoDispose<List<Offer>>(
  (ref) => ref.read(offerRepositoryProvider).list(),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final balance = ref.watch(_homeBalanceProvider);
    final offers = ref.watch(_homeOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HeroHeader(profile: profile, balance: balance),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _QuickActions(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ofertas recentes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/offers'),
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            _OffersSliver(offers: offers),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Header ────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.profile, required this.balance});

  final AsyncValue<CompanyProfile> profile;
  final AsyncValue<WalletBalance> balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bom dia 👋',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        profile.when(
                          data: (p) => Text(
                            p.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Skeleton(
                              width: 140, height: 18, radius: 6),
                          error: (_, __) => const Text('Empresa',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  profile.when(
                    data: (p) => _Avatar(initials: p.initials),
                    loading: () => const Skeleton(
                        width: 44, height: 44, radius: 22),
                    error: (_, __) => const _Avatar(initials: '?'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                loading: () =>
                    const Skeleton(width: 160, height: 36, radius: 8),
                error: (_, __) => const Text('—',
                    style:
                        TextStyle(color: Colors.white, fontSize: 32)),
              ),
              const SizedBox(height: 4),
              const Text(
                '1 UP\$ = R\$ 1,00',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Transferir',
          color: AppColors.primary,
          onTap: () => context.go('/transfer'),
        ),
        const SizedBox(width: 12),
        _QuickButton(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Extrato',
          color: AppColors.primaryDark,
          onTap: () => context.go('/wallet'),
        ),
        const SizedBox(width: 12),
        _QuickButton(
          icon: Icons.storefront_rounded,
          label: 'Publicar',
          color: AppColors.accentDark,
          onTap: () => context.push('/offers/new'),
        ),
        const SizedBox(width: 12),
        _QuickButton(
          icon: Icons.search_rounded,
          label: 'Explorar',
          color: AppColors.textSecondary,
          onTap: () => context.go('/offers'),
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Offers Sliver ───────────────────────────────────────────────────────────

class _OffersSliver extends StatelessWidget {
  const _OffersSliver({required this.offers});

  final AsyncValue<List<Offer>> offers;

  @override
  Widget build(BuildContext context) {
    return offers.when(
      data: (items) {
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyOffersCard(),
            ),
          );
        }
        final preview = items.take(4).toList();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: EdgeInsets.fromLTRB(
                  16, i == 0 ? 0 : 8, 16, i == preview.length - 1 ? 0 : 0),
              child: _OfferCard(offer: preview[i]),
            ),
            childCount: preview.length,
          ),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _OfferCardSkeleton(),
          ),
          childCount: 3,
        ),
      ),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  offer.companyName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (offer.category != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
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
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            kCurrency.format(offer.priceCents / 100.0),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 14,
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
        children: [
          Skeleton(width: 52, height: 52, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 120, height: 14),
                SizedBox(height: 6),
                Skeleton(width: 80, height: 12),
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

class _EmptyOffersCard extends StatelessWidget {
  const _EmptyOffersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma oferta ainda',
            style: TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.push('/offers/new'),
            icon: const Icon(Icons.add),
            label: const Text('Publicar primeira oferta'),
          ),
        ],
      ),
    );
  }
}
