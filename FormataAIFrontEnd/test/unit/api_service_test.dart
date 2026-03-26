import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:formataai/core/services/api_service.dart';

// Fake storage que roda em testes sem plataforma nativa.
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
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
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
  }) async =>
      _store[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.remove(key);

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map.unmodifiable(_store);

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.clear();

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.containsKey(key);

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
  void registerListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {}

  @override
  void unregisterListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {}

  @override
  void unregisterAllListenersForKey({required String key}) {}

  @override
  void unregisterAllListeners() {}
}

void main() {
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

  group('Token management', () {
    test('saveToken e getToken', () async {
      await api.saveToken('meu-jwt-token');
      final token = await api.getToken();
      expect(token, 'meu-jwt-token');
    });

    test('deleteToken remove token', () async {
      await api.saveToken('token-123');
      await api.deleteToken();
      final token = await api.getToken();
      expect(token, isNull);
    });

    test('getToken retorna null quando nao existe', () async {
      final token = await api.getToken();
      expect(token, isNull);
    });
  });

  group('HTTP GET', () {
    test('retorna dados corretamente', () async {
      dioAdapter.onGet(
        '/usuarios/buscar-perfil',
        (server) => server.reply(200, {
          'id': '1',
          'nome': 'Test',
          'email': 'test@test.com',
        }),
      );

      final res = await api.get('/usuarios/buscar-perfil');
      expect(res.statusCode, 200);
      expect(res.data['nome'], 'Test');
    });

    test('GET com query parameters', () async {
      dioAdapter.onGet(
        '/ia/conversas',
        (server) => server.reply(200, {
          'dados': [],
          'total': 0,
        }),
        queryParameters: {'pagina': 1, 'limite': 20},
      );

      final res = await api.get(
        '/ia/conversas',
        queryParameters: {'pagina': 1, 'limite': 20},
      );
      expect(res.statusCode, 200);
      expect(res.data['dados'], isEmpty);
    });

    test('GET erro 401', () async {
      dioAdapter.onGet(
        '/usuarios/buscar-perfil',
        (server) => server.reply(401, {'erro': 'Token inválido'}),
      );

      expect(
        () => api.get('/usuarios/buscar-perfil'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('HTTP POST', () {
    test('login retorna token e usuario', () async {
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(200, {
          'token': 'jwt-abc',
          'usuario': {
            'id': '1',
            'nome': 'Test User',
            'email': 'test@test.com',
            'provedor': 'EMAIL',
          },
        }),
        data: {'email': 'test@test.com', 'senha': '123456'},
      );

      final res = await api.post(
        '/auth/login',
        data: {'email': 'test@test.com', 'senha': '123456'},
      );
      expect(res.statusCode, 200);
      expect(res.data['token'], 'jwt-abc');
      expect(res.data['usuario']['nome'], 'Test User');
    });

    test('registro retorna usuario criado', () async {
      dioAdapter.onPost(
        '/auth/registrar',
        (server) => server.reply(201, {
          'token': 'jwt-novo',
          'usuario': {
            'id': '2',
            'nome': 'Novo User',
            'email': 'novo@test.com',
            'provedor': 'EMAIL',
          },
        }),
        data: {
          'nome': 'Novo User',
          'email': 'novo@test.com',
          'senha': 'senha123',
        },
      );

      final res = await api.post(
        '/auth/registrar',
        data: {
          'nome': 'Novo User',
          'email': 'novo@test.com',
          'senha': 'senha123',
        },
      );
      expect(res.statusCode, 201);
      expect(res.data['usuario']['email'], 'novo@test.com');
    });

    test('POST erro 400', () async {
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(400, {'erro': 'Email ou senha inválidos'}),
        data: {'email': 'wrong@test.com', 'senha': 'errada'},
      );

      expect(
        () => api.post(
          '/auth/login',
          data: {'email': 'wrong@test.com', 'senha': 'errada'},
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('HTTP PUT', () {
    test('atualizar conversa', () async {
      dioAdapter.onPut(
        '/ia/conversas/conv-1',
        (server) => server.reply(200, {
          'id': 'conv-1',
          'titulo': 'Titulo Atualizado',
          'categoria': 'PROFISSIONAL',
        }),
        data: {'titulo': 'Titulo Atualizado'},
      );

      final res = await api.put(
        '/ia/conversas/conv-1',
        data: {'titulo': 'Titulo Atualizado'},
      );
      expect(res.statusCode, 200);
      expect(res.data['titulo'], 'Titulo Atualizado');
    });
  });

  group('HTTP DELETE', () {
    test('deletar conversa', () async {
      dioAdapter.onDelete(
        '/ia/conversas/conv-1',
        (server) => server.reply(200, {'mensagem': 'Conversa deletada'}),
      );

      final res = await api.delete('/ia/conversas/conv-1');
      expect(res.statusCode, 200);
    });

    test('deletar conta', () async {
      dioAdapter.onDelete(
        '/auth/deletar-conta',
        (server) => server.reply(200, {'mensagem': 'Conta deletada'}),
      );

      final res = await api.delete('/auth/deletar-conta');
      expect(res.statusCode, 200);
    });
  });

  group('Respostas da API - formatos reais', () {
    test('buscar-perfil retorna usuario completo', () async {
      dioAdapter.onGet(
        '/usuarios/buscar-perfil',
        (server) => server.reply(200, {
          'id': 'user-uuid',
          'nome': 'João Silva',
          'email': 'joao@email.com',
          'fotoUrl': null,
          'provedor': 'EMAIL',
          'plano': 'GRATUITO',
          'criadoEm': '2025-01-01T00:00:00.000Z',
        }),
      );

      final res = await api.get('/usuarios/buscar-perfil');
      expect(res.data['id'], isNotEmpty);
      expect(res.data['provedor'], 'EMAIL');
      expect(res.data['plano'], 'GRATUITO');
    });

    test('estatisticas retorna contadores', () async {
      dioAdapter.onGet(
        '/usuarios/estatisticas',
        (server) => server.reply(200, {
          'consultasUsadas': 3,
          'limiteConsultas': 50,
          'consultasRestantes': 47,
          'plano': 'GRATUITO',
        }),
      );

      final res = await api.get('/usuarios/estatisticas');
      expect(res.data['consultasUsadas'], 3);
      expect(res.data['consultasRestantes'], 47);
    });

    test('listar conversas paginado', () async {
      dioAdapter.onGet(
        '/ia/conversas',
        (server) => server.reply(200, {
          'dados': [
            {
              'id': 'conv-1',
              'titulo': 'Aula de história',
              'categoria': 'ACADEMICO',
              'favoritada': false,
              'arquivada': false,
              'criadoEm': '2025-06-20T10:00:00.000Z',
            },
            {
              'id': 'conv-2',
              'titulo': 'Reunião semanal',
              'categoria': 'PROFISSIONAL',
              'favoritada': true,
              'arquivada': false,
              'criadoEm': '2025-06-19T14:30:00.000Z',
            },
          ],
          'total': 2,
          'pagina': 1,
          'limite': 20,
        }),
        queryParameters: {'pagina': 1, 'limite': 20},
      );

      final res = await api.get(
        '/ia/conversas',
        queryParameters: {'pagina': 1, 'limite': 20},
      );
      final dados = res.data['dados'] as List;
      expect(dados, hasLength(2));
      expect(dados[0]['categoria'], 'ACADEMICO');
      expect(dados[1]['favoritada'], true);
    });

    test('detalhes conversa individual', () async {
      dioAdapter.onGet(
        '/ia/conversas/conv-1',
        (server) => server.reply(200, {
          'id': 'conv-1',
          'titulo': 'Aula de história',
          'categoria': 'ACADEMICO',
          'favoritada': false,
          'arquivada': false,
          'criadoEm': '2025-06-20T10:00:00.000Z',
        }),
      );

      final res = await api.get('/ia/conversas/conv-1');
      expect(res.data['id'], 'conv-1');
      expect(res.data['titulo'], 'Aula de história');
    });

    test('mensagens de conversa', () async {
      dioAdapter.onGet(
        '/ia/conversas/conv-1/mensagens',
        (server) => server.reply(200, {
          'dados': [
            {
              'id': 'msg-1',
              'tipo': 'USUARIO',
              'conteudo': 'Transcrição do audio...',
              'transcricao': 'Transcrição do audio...',
              'criadoEm': '2025-06-20T10:01:00.000Z',
            },
            {
              'id': 'msg-2',
              'tipo': 'ASSISTENTE',
              'conteudo': '# Resumo\n\nTexto formatado pela IA...',
              'transcricao': null,
              'criadoEm': '2025-06-20T10:01:05.000Z',
            },
          ],
          'total': 2,
        }),
      );

      final res = await api.get('/ia/conversas/conv-1/mensagens');
      final msgs = res.data['dados'] as List;
      expect(msgs, hasLength(2));
      expect(msgs[0]['tipo'], 'USUARIO');
      expect(msgs[1]['tipo'], 'ASSISTENTE');
      expect(msgs[1]['transcricao'], isNull);
    });

    test('criar conversa', () async {
      dioAdapter.onPost(
        '/ia/conversas',
        (server) => server.reply(201, {
          'id': 'conv-new',
          'titulo': 'Nova conversa',
          'categoria': 'OUTRO',
          'favoritada': false,
          'arquivada': false,
          'criadoEm': '2025-06-21T12:00:00.000Z',
        }),
        data: {'titulo': 'Nova conversa', 'categoria': 'OUTRO'},
      );

      final res = await api.post(
        '/ia/conversas',
        data: {'titulo': 'Nova conversa', 'categoria': 'OUTRO'},
      );
      expect(res.statusCode, 201);
      expect(res.data['id'], 'conv-new');
    });

    test('alterar senha', () async {
      dioAdapter.onPut(
        '/auth/alterar-senha',
        (server) => server.reply(200, {'mensagem': 'Senha alterada'}),
        data: {'senhaAtual': 'antiga123', 'novaSenha': 'nova456'},
      );

      final res = await api.put(
        '/auth/alterar-senha',
        data: {'senhaAtual': 'antiga123', 'novaSenha': 'nova456'},
      );
      expect(res.statusCode, 200);
    });

    test('erro 409 email duplicado no registro', () async {
      dioAdapter.onPost(
        '/auth/registrar',
        (server) => server.reply(409, {
          'erro': 'Email já cadastrado',
        }),
        data: {
          'nome': 'Dup',
          'email': 'dup@test.com',
          'senha': '123456',
        },
      );

      expect(
        () => api.post(
          '/auth/registrar',
          data: {
            'nome': 'Dup',
            'email': 'dup@test.com',
            'senha': '123456',
          },
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            409,
          ),
        ),
      );
    });
  });
}
