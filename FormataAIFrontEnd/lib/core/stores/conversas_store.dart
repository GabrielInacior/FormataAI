import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Modelo de conversa.
class Conversa {
  final String id;
  final String titulo;
  final String categoria;
  final bool favoritada;
  final bool arquivada;
  final DateTime criadoEm;

  const Conversa({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.favoritada,
    required this.arquivada,
    required this.criadoEm,
  });

  factory Conversa.fromJson(Map<String, dynamic> json) => Conversa(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    categoria: json['categoria'] as String? ?? 'OUTRO',
    favoritada: json['favoritada'] as bool? ?? false,
    arquivada: json['arquivada'] as bool? ?? false,
    criadoEm: DateTime.parse(json['criadoEm'] as String),
  );
}

/// Modelo de mensagem.
class Mensagem {
  final String id;
  final String tipo; // USUARIO | ASSISTENTE
  final String conteudo;
  final String? transcricao;
  final String? audioUrl;
  final DateTime criadoEm;

  const Mensagem({
    required this.id,
    required this.tipo,
    required this.conteudo,
    this.transcricao,
    this.audioUrl,
    required this.criadoEm,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) => Mensagem(
    id: json['id'] as String,
    tipo: json['tipo'] as String,
    conteudo: json['conteudo'] as String? ?? '',
    transcricao: json['transcricao'] as String?,
    audioUrl: json['audioUrl'] as String?,
    criadoEm: DateTime.parse(json['criadoEm'] as String),
  );
}

/// Estatísticas do usuário.
class Estatisticas {
  final int consultasUsadas;
  final int limiteConsultas;
  final int consultasRestantes;
  final String plano;

  const Estatisticas({
    required this.consultasUsadas,
    required this.limiteConsultas,
    required this.consultasRestantes,
    required this.plano,
  });

  factory Estatisticas.fromJson(Map<String, dynamic> json) => Estatisticas(
    consultasUsadas: json['consultasUsadas'] as int,
    limiteConsultas: json['limiteConsultas'] as int,
    consultasRestantes: json['consultasRestantes'] as int,
    plano: json['plano'] as String,
  );
}

/// Store centralizado de conversas e IA.
class ConversasStore extends ChangeNotifier {
  final _api = ApiService.instance;

  List<Conversa> _conversas = [];
  List<Conversa> _arquivadas = [];
  List<Mensagem> _mensagens = [];
  Conversa? _conversaAtual;
  Estatisticas? _estatisticas;
  bool _isLoading = false;
  final Map<String, bool> _processando = {};
  String? _erro;

  List<Conversa> get conversas => _conversas;
  List<Conversa> get arquivadas => _arquivadas;
  List<Mensagem> get mensagens => _mensagens;
  Conversa? get conversaAtual => _conversaAtual;
  Estatisticas? get estatisticas => _estatisticas;
  bool get isLoading => _isLoading;

  /// Global — true se qualquer conversa estiver processando.
  bool get isProcessando => _processando.values.any((v) => v);
  String? get erro => _erro;

  /// Verifica se uma conversa específica está processando.
  bool isConversaProcessando(String conversaId) =>
      _processando[conversaId] ?? false;

  /// Retorna true se o limite de consultas foi atingido.
  bool get limiteAtingido =>
      _estatisticas != null && _estatisticas!.consultasRestantes <= 0;

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  // ─── Conversas ────────────────────────────────

  Future<void> carregarConversas({int pagina = 1, String? busca}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{'pagina': pagina, 'limite': 20};
      if (busca != null && busca.isNotEmpty) params['busca'] = busca;

      final res = await _api.get('/ia/conversas', queryParameters: params);
      final data = res.data as Map<String, dynamic>;
      final itens =
          (data['dados'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      _conversas = itens.map(Conversa.fromJson).toList();
    } on DioException catch (e) {
      _erro = _extrairErro(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Conversa?> criarConversa({
    String titulo = 'Nova conversa',
    String categoria = 'OUTRO',
  }) async {
    try {
      final res = await _api.post(
        '/ia/conversas',
        data: {'titulo': titulo, 'categoria': categoria},
      );
      final conversa = Conversa.fromJson(res.data as Map<String, dynamic>);
      _conversas.insert(0, conversa);
      _conversaAtual = conversa;
      _mensagens = [];
      notifyListeners();
      return conversa;
    } on DioException catch (e) {
      _erro = _extrairErro(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> selecionarConversa(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/ia/conversas/$id');
      _conversaAtual = Conversa.fromJson(res.data as Map<String, dynamic>);
      await carregarMensagens(id);
    } on DioException catch (e) {
      _erro = _extrairErro(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarConversa(String id, Map<String, dynamic> dados) async {
    try {
      await _api.put('/ia/conversas/$id', data: dados);
      await carregarConversas();
    } catch (_) {}
  }

  Future<void> deletarConversa(String id) async {
    try {
      await _api.delete('/ia/conversas/$id');
      _conversas.removeWhere((c) => c.id == id);
      if (_conversaAtual?.id == id) {
        _conversaAtual = null;
        _mensagens = [];
      }
      notifyListeners();
    } catch (_) {}
  }

  // ─── Mensagens ────────────────────────────────

  Future<void> carregarMensagens(String conversaId) async {
    try {
      final res = await _api.get('/ia/conversas/$conversaId/mensagens');
      final data = res.data as Map<String, dynamic>;
      final itens =
          (data['dados'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _mensagens = itens.map(Mensagem.fromJson).toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Envia áudio para transcrição + resposta IA.
  /// Retorna o ID da conversa processada (para navegação).
  Future<String?> processarAudio(
    String filePath, {
    String? conversaId,
    String? formato,
  }) async {
    // Verifica limite antes de enviar
    if (limiteAtingido) {
      _erro = 'Limite diário de consultas atingido. Tente novamente amanhã.';
      notifyListeners();
      return null;
    }

    // Se não tem conversa, cria uma
    final cId = conversaId ?? _conversaAtual?.id ?? (await criarConversa())?.id;
    if (cId == null) return null;

    _processando[cId] = true;
    notifyListeners();
    try {
      final extraFields = <String, dynamic>{};
      extraFields['conversaId'] = cId;
      if (formato != null) extraFields['formato'] = formato;

      final res = await _api.upload(
        '/ia/processar',
        filePath: filePath,
        extraFields: extraFields.isNotEmpty ? extraFields : null,
      );

      final data = res.data as Map<String, dynamic>;

      // Adiciona mensagens do usuário e assistente
      if (data['transcricao'] != null) {
        _mensagens.add(
          Mensagem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tipo: 'USUARIO',
            conteudo: data['transcricao'] as String,
            transcricao: data['transcricao'] as String?,
            audioUrl: data['audioUrl'] as String?,
            criadoEm: DateTime.now(),
          ),
        );
      }
      if (data['resposta'] != null) {
        _mensagens.add(
          Mensagem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tipo: 'ASSISTENTE',
            conteudo: data['resposta'] as String,
            criadoEm: DateTime.now(),
          ),
        );
      }

      // Atualiza lista de conversas e estatísticas
      await carregarConversas();
      await carregarEstatisticas();
      return cId;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        _erro = 'Limite diário de consultas atingido. Tente novamente amanhã.';
        await carregarEstatisticas();
      } else {
        _erro = _extrairErro(e);
      }
      return null;
    } finally {
      _processando.remove(cId);
      notifyListeners();
    }
  }

  // ─── Estatísticas ─────────────────────────────

  Future<void> carregarEstatisticas() async {
    try {
      final res = await _api.get('/usuarios/estatisticas');
      _estatisticas = Estatisticas.fromJson(res.data as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {}
  }

  // ─── Reprocessar ──────────────────────────────

  /// Reutiliza uma transcrição existente com um novo formato.
  /// Cria uma nova conversa e retorna o ID dela.
  Future<String?> reprocessarAudio(String mensagemId, String formato) async {
    if (limiteAtingido) {
      _erro = 'Limite diário de consultas atingido. Tente novamente amanhã.';
      notifyListeners();
      return null;
    }

    _processando['reprocessar_$mensagemId'] = true;
    notifyListeners();
    try {
      final res = await _api.post(
        '/ia/reprocessar',
        data: {'mensagemId': mensagemId, 'formato': formato},
      );
      final data = res.data as Map<String, dynamic>;
      final cId = data['conversaId'] as String?;

      await carregarConversas();
      await carregarEstatisticas();
      return cId;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        _erro = 'Limite diário de consultas atingido. Tente novamente amanhã.';
        await carregarEstatisticas();
      } else {
        _erro = _extrairErro(e);
      }
      return null;
    } finally {
      _processando.remove('reprocessar_$mensagemId');
      notifyListeners();
    }
  }

  // ─── Arquivadas ────────────────────────────────

  Future<void> carregarArquivadas({String? busca}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{
        'pagina': 1,
        'limite': 50,
        'arquivada': 'true',
      };
      if (busca != null && busca.isNotEmpty) params['busca'] = busca;

      final res = await _api.get('/ia/conversas', queryParameters: params);
      final data = res.data as Map<String, dynamic>;
      final itens =
          (data['dados'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      _arquivadas = itens.map(Conversa.fromJson).toList();
    } on DioException catch (e) {
      _erro = _extrairErro(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Internos ─────────────────────────────────

  String _extrairErro(DioException e) {
    if (e.response?.data is Map) {
      return (e.response!.data as Map)['erro'] as String? ??
          'Erro desconhecido';
    }
    return 'Erro de conexão';
  }
}
