import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    ('/home', Icons.home_outlined, Icons.home_rounded, 'Início'),
    ('/wallet', Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded, 'Carteira'),
    ('/offers', Icons.storefront_outlined, Icons.storefront_rounded,
        'Mercado'),
    ('/profile', Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go(_tabs[i].$1),
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.$2),
                selectedIcon: Icon(tab.$3),
                label: tab.$4,
              ),
          ],
        ),
      ),
    );
  }
}
