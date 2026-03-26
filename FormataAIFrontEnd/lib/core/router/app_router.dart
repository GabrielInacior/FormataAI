import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../stores/auth_store.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/registro_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/conversas/screens/conversa_screen.dart';
import '../../features/conversas/screens/arquivadas_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter criarRouter(AuthStore authStore) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  debugLogDiagnostics: false,
  refreshListenable: authStore,
  redirect: (context, state) {
    final logado = authStore.isLoggedIn;
    final naAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/registro';

    if (!logado && !naAuth) return '/login';
    if (logado && naAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/registro', builder: (_, _) => const RegistroScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/conversa/:id',
      builder: (_, state) =>
          ConversaScreen(conversaId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/perfil', builder: (_, _) => const PerfilScreen()),
    GoRoute(path: '/arquivadas', builder: (_, _) => const ArquivadasScreen()),
  ],
);
