import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/catalog/screens/products_screen.dart';
import '../features/pos/screens/cart_screen.dart';
import '../features/pos/screens/pos_payment_screen.dart';
import '../features/pos/screens/pos_screen.dart';
import '../features/purchases/screens/purchases_screen.dart';
import '../features/purchases/screens/suppliers_screen.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

class Routes {
  Routes._();
  static const splash = '/';
  static const login = '/login';

  static const pos = '/pos';
  static const products = '/products';
  static const purchases = '/purchases';
  static const suppliers = '/suppliers';

  static const cart = '/pos/cart';
  static const posPayment = '/pos/payment';
}

/// Rebuilds the redirect whenever the auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (auth.status == AuthStatus.unknown) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      if (auth.status == AuthStatus.signedOut) {
        return loc == Routes.login ? null : Routes.login;
      }
      if (loc == Routes.splash || loc == Routes.login) return Routes.pos;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),

      // Full-screen POS flow pages (outside the tab shell so the bottom bar hides).
      GoRoute(path: Routes.cart, builder: (_, __) => const CartScreen()),
      GoRoute(path: Routes.posPayment, builder: (_, __) => const PosPaymentScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.pos, builder: (_, __) => const PosScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.products, builder: (_, __) => const ProductsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.purchases, builder: (_, __) => const PurchasesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.suppliers, builder: (_, __) => const SuppliersScreen()),
          ]),
        ],
      ),
    ],
  );
});
