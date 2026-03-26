import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formataai/core/services/api_service.dart';
import 'package:formataai/core/stores/auth_store.dart';
import 'package:formataai/core/stores/conversas_store.dart';

/// Testes de integração que simulam fluxos completos do app
/// usando respostas no formato real da API do backend.

// Reutiliza FakeSecureStorage do api_service_test
class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
    else _store.remove(key);
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.remove(key);

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => Map.unmodifiable(_store);

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.clear();

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.containsKey(key);

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async => true;

  @override
  Stream<bool>? get onCupertinoProtectedDataAvailabilityChanged => null;

  @override
  AndroidOptions get aOptions => AndroidOptions.defaultOptions;
  @override
  IOSOptions get iOptions => IOSOptions.defaultOptions;
  @override
  LinuxOptions get lOptions => LinuxOptions.defaultOptions;
  @override
  AppleOptions get mOptions => MacOsOptions.defaultOptions;
  @override
  WebOptions get webOptions => WebOptions.defaultOptions;
  @override
  WindowsOptions get wOptions => WindowsOptions.defaultOptions;

  @override
  Map<String, List<ValueChanged<String?>>> get getListeners => {};

  @override
  void registerListener({required String key, required ValueChanged<String?> listener}) {}
  @override
  void unregisterListener({required String key, required ValueChanged<String?> listener}) {}
  @override
  void unregisterAllListenersForKey({required String key}) {}
  @override
  void unregisterAllListeners() {}
}

void main() {
  group('Fluxo completo: Registro → Login → Operações', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late FakeSecureStorage storage;
    late ApiService api;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
      dioAdapter = DioAdapter(dio: dio);
      storage = FakeSecureStorage();
      api = ApiService.test(dio, storage);
    });

    test('registro cria usuario e salva token', () async {
      dioAdapter.onPost(
        '/auth/registrar',
        (server) => server.reply(201, {
          'token': 'jwt-registro-123',
          'usuario': {
            'id': 'user-uuid-1',
            'nome': 'Novo Usuário',
            'email': 'novo@test.com',
            'fotoUrl': null,
            'provedor': 'EMAIL',
          },
        }),
        data: {
          'nome': 'Novo Usuário',
          'email': 'novo@test.com',
          'senha': 'senha123',
        },
      );

      final res = await api.post('/auth/registrar', data: {
        'nome': 'Novo Usuário',
        'email': 'novo@test.com',
        'senha': 'senha123',
      });

      final data = res.data as Map<String, dynamic>;
      expect(data['token'], isNotEmpty);

      await api.saveToken(data['token'] as String);
      final savedToken = await api.getToken();
      expect(savedToken, 'jwt-registro-123');

      final usuario = UsuarioLogado.fromJson(
        data['usuario'] as Map<String, dynamic>,
      );
      expect(usuario.nome, 'Novo Usuário');
      expect(usuario.email, 'novo@test.com');
      expect(usuario.provedor, 'EMAIL');
    });

    test('login e buscar perfil', () async {
      // 1. Login
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(200, {
          'token': 'jwt-login-456',
          'usuario': {
            'id': 'user-uuid-2',
            'nome': 'João Test',
            'email': 'joao@test.com',
            'fotoUrl': null,
            'provedor': 'EMAIL',
          },
        }),
        data: {'email': 'joao@test.com', 'senha': '123456'},
      );

      final loginRes = await api.post('/auth/login', data: {
        'email': 'joao@test.com',
        'senha': '123456',
      });

      await api.saveToken(loginRes.data['token'] as String);

      // 2. Buscar perfil
      dioAdapter.onGet(
        '/usuarios/buscar-perfil',
        (server) => server.reply(200, {
          'id': 'user-uuid-2',
          'nome': 'João Test',
          'email': 'joao@test.com',
          'fotoUrl': null,
          'provedor': 'EMAIL',
          'plano': 'GRATUITO',
          'criadoEm': '2025-01-01T00:00:00.000Z',
        }),
      );

      final perfilRes = await api.get('/usuarios/buscar-perfil');
      final usuario = UsuarioLogado.fromJson(
        perfilRes.data as Map<String, dynamic>,
      );
      expect(usuario.id, 'user-uuid-2');
      expect(usuario.nome, 'João Test');
    });

    test('fluxo CRUD de conversas', () async {
      // 1. Criar conversa
      dioAdapter.onPost(
        '/ia/conversas',
        (server) => server.reply(201, {
          'id': 'conv-new-1',
          'titulo': 'Teste CRUD',
          'categoria': 'ACADEMICO',
          'favoritada': false,
          'arquivada': false,
          'criadoEm': '2025-06-21T12:00:00.000Z',
        }),
        data: {'titulo': 'Teste CRUD', 'categoria': 'ACADEMICO'},
      );

      final criarRes = await api.post('/ia/conversas', data: {
        'titulo': 'Teste CRUD',
        'categoria': 'ACADEMICO',
      });
      final convCriada = Conversa.fromJson(
        criarRes.data as Map<String, dynamic>,
      );
      expect(convCriada.id, 'conv-new-1');
      expect(convCriada.titulo, 'Teste CRUD');
      expect(convCriada.categoria, 'ACADEMICO');

      // 2. Listar conversas
      dioAdapter.onGet(
        '/ia/conversas',
        (server) => server.reply(200, {
          'dados': [
            {
              'id': 'conv-new-1',
              'titulo': 'Teste CRUD',
              'categoria': 'ACADEMICO',
              'favoritada': false,
              'arquivada': false,
              'criadoEm': '2025-06-21T12:00:00.000Z',
            },
          ],
          'total': 1,
          'pagina': 1,
          'limite': 20,
        }),
        queryParameters: {'pagina': 1, 'limite': 20},
      );

      final listarRes = await api.get(
        '/ia/conversas',
        queryParameters: {'pagina': 1, 'limite': 20},
      );
      final dados = (listarRes.data['dados'] as List)
          .cast<Map<String, dynamic>>()
          .map(Conversa.fromJson)
          .toList();
      expect(dados, hasLength(1));
      expect(dados.first.id, 'conv-new-1');

      // 3. Atualizar conversa
      dioAdapter.onPut(
        '/ia/conversas/conv-new-1',
        (server) => server.reply(200, {
          'id': 'conv-new-1',
          'titulo': 'Titulo Atualizado',
          'categoria': 'ACADEMICO',
          'favoritada': true,
          'arquivada': false,
          'criadoEm': '2025-06-21T12:00:00.000Z',
        }),
        data: {'titulo': 'Titulo Atualizado', 'favoritada': true},
      );

      final atualizarRes = await api.put(
        '/ia/conversas/conv-new-1',
        data: {'titulo': 'Titulo Atualizado', 'favoritada': true},
      );
      final convAtualizada = Conversa.fromJson(
        atualizarRes.data as Map<String, dynamic>,
      );
      expect(convAtualizada.titulo, 'Titulo Atualizado');
      expect(convAtualizada.favoritada, true);

      // 4. Deletar conversa
      dioAdapter.onDelete(
        '/ia/conversas/conv-new-1',
        (server) => server.reply(200, {'mensagem': 'Conversa deletada'}),
      );

      final deleteRes = await api.delete('/ia/conversas/conv-new-1');
      expect(deleteRes.statusCode, 200);
    });

    test('fluxo mensagens e processamento IA', () async {
      // 1. Buscar mensagens
      dioAdapter.onGet(
        '/ia/conversas/conv-1/mensagens',
        (server) => server.reply(200, {
          'dados': [
            {
              'id': 'msg-1',
              'tipo': 'USUARIO',
              'conteudo': 'Transcrição do áudio original',
              'transcricao': 'Transcrição do áudio original',
              'criadoEm': '2025-06-20T10:01:00.000Z',
            },
            {
              'id': 'msg-2',
              'tipo': 'ASSISTENTE',
              'conteudo':
                  '# Resumo da Aula\n\n## Introdução\nO professor abordou...\n\n## Conclusão\nEm resumo...',
              'transcricao': null,
              'criadoEm': '2025-06-20T10:01:05.000Z',
            },
          ],
          'total': 2,
        }),
      );

      final msgRes = await api.get('/ia/conversas/conv-1/mensagens');
      final mensagens = (msgRes.data['dados'] as List)
          .cast<Map<String, dynamic>>()
          .map(Mensagem.fromJson)
          .toList();

      expect(mensagens, hasLength(2));
      expect(mensagens[0].tipo, 'USUARIO');
      expect(mensagens[0].transcricao, isNotNull);
      expect(mensagens[1].tipo, 'ASSISTENTE');
      expect(mensagens[1].transcricao, isNull);
      expect(mensagens[1].conteudo, contains('# Resumo'));
    });

    test('fluxo estatisticas e limites', () async {
      dioAdapter.onGet(
        '/usuarios/estatisticas',
        (server) => server.reply(200, {
          'consultasUsadas': 15,
          'limiteConsultas': 50,
          'consultasRestantes': 35,
          'plano': 'GRATUITO',
        }),
      );

      final res = await api.get('/usuarios/estatisticas');
      final stats = Estatisticas.fromJson(res.data as Map<String, dynamic>);

      expect(stats.consultasUsadas, 15);
      expect(stats.limiteConsultas, 50);
      expect(stats.consultasRestantes, 35);
      expect(stats.plano, 'GRATUITO');

      // Valida contagem coerente
      expect(
        stats.consultasUsadas + stats.consultasRestantes,
        stats.limiteConsultas,
      );
    });

    test('fluxo alterar senha', () async {
      dioAdapter.onPut(
        '/auth/alterar-senha',
        (server) => server.reply(200, {
          'mensagem': 'Senha alterada com sucesso',
        }),
        data: {'senhaAtual': 'senha123', 'novaSenha': 'novaSenha456'},
      );

      final res = await api.put('/auth/alterar-senha', data: {
        'senhaAtual': 'senha123',
        'novaSenha': 'novaSenha456',
      });
      expect(res.statusCode, 200);
      expect(res.data['mensagem'], contains('Senha alterada'));
    });

    test('fluxo deletar conta', () async {
      dioAdapter.onDelete(
        '/auth/deletar-conta',
        (server) => server.reply(200, {
          'mensagem': 'Conta deletada com sucesso',
        }),
      );

      final res = await api.delete('/auth/deletar-conta');
      expect(res.statusCode, 200);

      // Após deletar conta, remove token
      await api.deleteToken();
      expect(await api.getToken(), isNull);
    });

    test('fluxo Google OAuth', () async {
      dioAdapter.onPost(
        '/auth/google',
        (server) => server.reply(200, {
          'token': 'jwt-google-789',
          'usuario': {
            'id': 'user-google-1',
            'nome': 'Google User',
            'email': 'google@gmail.com',
            'fotoUrl': 'https://lh3.googleusercontent.com/avatar.jpg',
            'provedor': 'GOOGLE',
          },
        }),
        data: {'idToken': 'google-id-token-mock'},
      );

      final res = await api.post('/auth/google', data: {
        'idToken': 'google-id-token-mock',
      });

      final data = res.data as Map<String, dynamic>;
      final usuario = UsuarioLogado.fromJson(
        data['usuario'] as Map<String, dynamic>,
      );

      expect(usuario.provedor, 'GOOGLE');
      expect(usuario.fotoUrl, isNotNull);
      expect(usuario.email, 'google@gmail.com');
    });
  });

  group('Cenários de erro', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late FakeSecureStorage storage;
    late ApiService api;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
      dioAdapter = DioAdapter(dio: dio);
      storage = FakeSecureStorage();
      api = ApiService.test(dio, storage);
    });

    test('login com credenciais invalidas', () async {
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(400, {
          'erro': 'Email ou senha inválidos',
        }),
        data: {'email': 'wrong@email.com', 'senha': 'wrongpass'},
      );

      try {
        await api.post('/auth/login', data: {
          'email': 'wrong@email.com',
          'senha': 'wrongpass',
        });
        fail('Deveria ter lançado DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 400);
        expect(e.response?.data['erro'], 'Email ou senha inválidos');
      }
    });

    test('token expirado retorna 401', () async {
      dioAdapter.onGet(
        '/usuarios/buscar-perfil',
        (server) => server.reply(401, {
          'erro': 'Token expirado ou inválido',
        }),
      );

      try {
        await api.get('/usuarios/buscar-perfil');
        fail('Deveria ter lançado DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }
    });

    test('email duplicado no registro retorna 409', () async {
      dioAdapter.onPost(
        '/auth/registrar',
        (server) => server.reply(409, {
          'erro': 'Email já cadastrado',
        }),
        data: {
          'nome': 'Dup',
          'email': 'existente@test.com',
          'senha': '123456',
        },
      );

      try {
        await api.post('/auth/registrar', data: {
          'nome': 'Dup',
          'email': 'existente@test.com',
          'senha': '123456',
        });
        fail('Deveria ter lançado DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 409);
        expect(e.response?.data['erro'], 'Email já cadastrado');
      }
    });

    test('conversa nao encontrada retorna 404', () async {
      dioAdapter.onGet(
        '/ia/conversas/id-inexistente',
        (server) => server.reply(404, {
          'erro': 'Conversa não encontrada',
        }),
      );

      try {
        await api.get('/ia/conversas/id-inexistente');
        fail('Deveria ter lançado DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
      }
    });

    test('senha atual incorreta ao alterar', () async {
      dioAdapter.onPut(
        '/auth/alterar-senha',
        (server) => server.reply(400, {
          'erro': 'Senha atual incorreta',
        }),
        data: {'senhaAtual': 'errada', 'novaSenha': 'nova123'},
      );

      try {
        await api.put('/auth/alterar-senha', data: {
          'senhaAtual': 'errada',
          'novaSenha': 'nova123',
        });
        fail('Deveria ter lançado DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 400);
        expect(e.response?.data['erro'], 'Senha atual incorreta');
      }
    });

    test('limite de consultas excedido', () async {
      dioAdapter.onPost(
        '/ia/processar',
        (server) => server.reply(429, {
          'erro': 'Limite de consultas atingido',
        }),
        data: Matchers.any,
      );

      try {
        // Usando post diretamente (upload usa FormData)
        await api.post('/ia/processar', data: {});
        fail('Deveria ter lançado DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 429);
        expect(e.response?.data['erro'], contains('Limite'));
      }
    });
  });
}
