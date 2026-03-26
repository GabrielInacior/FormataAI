import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/stores/conversas_store.dart';

void main() {
  group('Conversa model', () {
    test('fromJson cria instancia corretamente', () {
      final json = {
        'id': 'conv-1',
        'titulo': 'Minha conversa',
        'categoria': 'ACADEMICO',
        'favoritada': true,
        'arquivada': false,
        'criadoEm': '2025-01-15T10:30:00.000Z',
      };

      final conversa = Conversa.fromJson(json);

      expect(conversa.id, 'conv-1');
      expect(conversa.titulo, 'Minha conversa');
      expect(conversa.categoria, 'ACADEMICO');
      expect(conversa.favoritada, true);
      expect(conversa.arquivada, false);
      expect(conversa.criadoEm.year, 2025);
    });

    test('fromJson com valores default', () {
      final json = {
        'id': 'conv-2',
        'titulo': 'Sem categoria',
        'criadoEm': '2025-06-01T00:00:00.000Z',
      };

      final conversa = Conversa.fromJson(json);

      expect(conversa.categoria, 'OUTRO');
      expect(conversa.favoritada, false);
      expect(conversa.arquivada, false);
    });
  });

  group('Mensagem model', () {
    test('fromJson USUARIO', () {
      final json = {
        'id': 'msg-1',
        'tipo': 'USUARIO',
        'conteudo': 'Olá mundo',
        'transcricao': 'Olá mundo transcrito',
        'criadoEm': '2025-01-15T10:31:00.000Z',
      };

      final msg = Mensagem.fromJson(json);

      expect(msg.id, 'msg-1');
      expect(msg.tipo, 'USUARIO');
      expect(msg.conteudo, 'Olá mundo');
      expect(msg.transcricao, 'Olá mundo transcrito');
    });

    test('fromJson ASSISTENTE sem transcricao', () {
      final json = {
        'id': 'msg-2',
        'tipo': 'ASSISTENTE',
        'conteudo': 'Resposta formatada...',
        'criadoEm': '2025-01-15T10:32:00.000Z',
      };

      final msg = Mensagem.fromJson(json);

      expect(msg.tipo, 'ASSISTENTE');
      expect(msg.transcricao, isNull);
      expect(msg.conteudo, 'Resposta formatada...');
    });

    test('fromJson conteudo null usa string vazia', () {
      final json = {
        'id': 'msg-3',
        'tipo': 'USUARIO',
        'conteudo': null,
        'criadoEm': '2025-01-15T10:33:00.000Z',
      };

      final msg = Mensagem.fromJson(json);
      expect(msg.conteudo, '');
    });
  });

  group('Estatisticas model', () {
    test('fromJson correto', () {
      final json = {
        'consultasUsadas': 5,
        'limiteConsultas': 50,
        'consultasRestantes': 45,
        'plano': 'GRATUITO',
      };

      final stats = Estatisticas.fromJson(json);

      expect(stats.consultasUsadas, 5);
      expect(stats.limiteConsultas, 50);
      expect(stats.consultasRestantes, 45);
      expect(stats.plano, 'GRATUITO');
    });
  });

  group('ConversasStore', () {
    late ConversasStore store;

    setUp(() {
      store = ConversasStore();
    });

    test('inicia vazio', () {
      expect(store.conversas, isEmpty);
      expect(store.mensagens, isEmpty);
      expect(store.conversaAtual, isNull);
      expect(store.estatisticas, isNull);
      expect(store.isLoading, false);
      expect(store.isProcessando, false);
      expect(store.erro, isNull);
    });

    test('limparErro limpa e notifica', () {
      int count = 0;
      store.addListener(() => count++);

      store.limparErro();
      expect(store.erro, isNull);
      expect(count, 1);
    });
  });
}
