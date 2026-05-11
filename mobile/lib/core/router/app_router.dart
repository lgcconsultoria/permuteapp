import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/offers/offer_list_screen.dart';
import '../../features/offers/offer_create_screen.dart';
import '../../features/wallet/transfer_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../api/api_client.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(tokenStorageProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final token = await storage.readAccess();
      final loggedIn = token != null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/wallet';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          GoRoute(path: '/transfer', builder: (_, __) => const TransferScreen()),
          GoRoute(path: '/offers', builder: (_, __) => const OfferListScreen()),
          GoRoute(
            path: '/offers/new',
            builder: (_, __) => const OfferCreateScreen(),
          ),
        ],
      ),
    ],
  );
});
