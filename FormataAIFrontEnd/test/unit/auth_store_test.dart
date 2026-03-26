import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/stores/auth_store.dart';

void main() {
  group('UsuarioLogado', () {
    test('fromJson cria instancia corretamente', () {
      final json = {
        'id': '123',
        'nome': 'João Silva',
        'email': 'joao@test.com',
        'fotoUrl': 'https://foto.com/joao.jpg',
        'provedor': 'EMAIL',
      };

      final user = UsuarioLogado.fromJson(json);

      expect(user.id, '123');
      expect(user.nome, 'João Silva');
      expect(user.email, 'joao@test.com');
      expect(user.fotoUrl, 'https://foto.com/joao.jpg');
      expect(user.provedor, 'EMAIL');
    });

    test('fromJson com fotoUrl null', () {
      final json = {
        'id': '123',
        'nome': 'Maria',
        'email': 'maria@test.com',
        'fotoUrl': null,
        'provedor': 'GOOGLE',
      };

      final user = UsuarioLogado.fromJson(json);
      expect(user.fotoUrl, isNull);
      expect(user.provedor, 'GOOGLE');
    });

    test('fromJson sem provedor usa EMAIL como padrao', () {
      final json = {
        'id': '123',
        'nome': 'Test',
        'email': 'test@test.com',
      };

      final user = UsuarioLogado.fromJson(json);
      expect(user.provedor, 'EMAIL');
    });
  });

  group('AuthStore', () {
    late AuthStore store;

    setUp(() {
      store = AuthStore();
    });

    test('inicia sem usuario logado', () {
      expect(store.usuario, isNull);
      expect(store.isLoggedIn, false);
      expect(store.isLoading, false);
      expect(store.erro, isNull);
    });

    test('limparErro limpa o erro e notifica', () {
      int count = 0;
      store.addListener(() => count++);

      store.limparErro();
      expect(store.erro, isNull);
      expect(count, 1);
    });
  });
}
