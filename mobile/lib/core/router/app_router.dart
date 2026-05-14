import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/offers/my_offers_screen.dart';
import '../../features/offers/offer_create_screen.dart';
import '../../features/offers/offer_list_screen.dart';
import '../../features/profile/profile_screen.dart';
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
      final publicRoutes = ['/login', '/register'];
      final isPublic = publicRoutes.contains(state.matchedLocation);

      if (!loggedIn && !isPublic) return '/login';
      if (loggedIn && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          GoRoute(path: '/transfer', builder: (_, __) => const TransferScreen()),
          GoRoute(path: '/offers', builder: (_, __) => const OfferListScreen()),
          GoRoute(
            path: '/offers/new',
            builder: (_, __) => const OfferCreateScreen(),
          ),
          GoRoute(
            path: '/offers/mine',
            builder: (_, __) => const MyOffersScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
