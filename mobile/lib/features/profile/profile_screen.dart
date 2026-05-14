import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/skeleton.dart';
import '../auth/auth_repository.dart';
import 'profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: profile.when(
                      data: (p) => Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2),
                            ),
                            child: Center(
                              child: Text(
                                p.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            p.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (p.nomeFantasia != null)
                            Text(
                              p.razaoSocial,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Empresa ativa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => Column(
                        children: const [
                          Skeleton(
                              width: 72, height: 72, radius: 36),
                          SizedBox(height: 14),
                          Skeleton(width: 140, height: 20),
                          SizedBox(height: 8),
                          Skeleton(width: 80, height: 22, radius: 20),
                        ],
                      ),
                      error: (e, _) => const Icon(Icons.business,
                          color: Colors.white54, size: 48),
                    ),
                  ),

                  // Dados
                  profile.when(
                    data: (p) => _InfoCard(profile: p),
                    loading: () => const _InfoCardSkeleton(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // Ações
                  _ActionsCard(onLogout: () => _logout(context, ref)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text(
            'Tem certeza que deseja sair? Você precisará entrar novamente.'),
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
            child: const Text('Sair'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).logout();
      ref.read(tokenStorageProvider).clear();
    } catch (_) {}
    if (context.mounted) context.go('/login');
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile});
  final CompanyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados da empresa',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          if (profile.cnpj != null) ...[
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'CNPJ',
              value: formatCnpj(profile.cnpj!),
            ),
            const Divider(height: 24),
          ],
          _InfoRow(
            icon: Icons.alternate_email_rounded,
            label: 'E-mail',
            value: profile.email,
          ),
          if (profile.phone != null) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              value: formatPhone(profile.phone!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryWash,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCardSkeleton extends StatelessWidget {
  const _InfoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Skeleton(height: 14, width: 120),
          SizedBox(height: 20),
          Skeleton(height: 36),
          SizedBox(height: 16),
          Skeleton(height: 36),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.storefront_outlined,
            label: 'Minhas ofertas',
            onTap: () => context.push('/offers/mine'),
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.help_outline_rounded,
            label: 'Sobre o PermuteApp',
            onTap: () {},
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.logout_rounded,
            label: 'Sair da conta',
            onTap: onLogout,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.debit : AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.debit.withOpacity(0.08)
              : AppColors.primaryWash,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: destructive ? AppColors.debit : AppColors.primary),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted, size: 20),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
