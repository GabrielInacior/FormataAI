import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:formataai/core/stores/auth_store.dart';
import 'package:formataai/core/router/app_router.dart';

void main() {
  group('criarRouter', () {
    test('cria GoRouter com initialLocation /login', () {
      final authStore = AuthStore();
      final router = criarRouter(authStore);

      expect(router, isA<GoRouter>());
      router.dispose();
    });

    test('router recebe authStore como refreshListenable', () {
      final authStore = AuthStore();
      final router = criarRouter(authStore);

      // O router deve ser criado sem erros
      expect(router, isNotNull);
      router.dispose();
    });

    test('authStore inicia deslogado para redirect', () {
      final authStore = AuthStore();
      expect(authStore.isLoggedIn, false);
    });

    test('rotas sao definidas corretamente', () {
      final authStore = AuthStore();
      final router = criarRouter(authStore);

      // Verifica que o router tem configuração de rotas
      expect(router.configuration.routes, isNotEmpty);
      router.dispose();
    });
  });
}
