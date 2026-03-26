import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

const _webClientId =
    '561072028296-ishse2t75fvevb99v1g8q353rm84gav8.apps.googleusercontent.com';

final _googleSignIn = GoogleSignIn.instance;
bool _googleSignInInitialized = false;

Future<void> _ensureGoogleInit() async {
  if (_googleSignInInitialized) return;
  await _googleSignIn.initialize(serverClientId: _webClientId);
  _googleSignInInitialized = true;
}

/// Dados do usuário logado.
class UsuarioLogado {
  final String id;
  final String nome;
  final String email;
  final String? fotoUrl;
  final String provedor;

  const UsuarioLogado({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoUrl,
    required this.provedor,
  });

  factory UsuarioLogado.fromJson(Map<String, dynamic> json) => UsuarioLogado(
    id: json['id'] as String,
    nome: json['nome'] as String,
    email: json['email'] as String,
    fotoUrl: json['fotoUrl'] as String?,
    provedor: json['provedor'] as String? ?? 'EMAIL',
  );
}

/// Store centralizado de autenticação.
class AuthStore extends ChangeNotifier {
  final _api = ApiService.instance;

  UsuarioLogado? _usuario;
  bool _isLoading = false;
  String? _erro;

  UsuarioLogado? get usuario => _usuario;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _usuario != null;
  String? get erro => _erro;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  /// Tenta restaurar sessão com token salvo.
  Future<bool> tentarRestaurar() async {
    final token = await _api.getToken();
    if (token == null) return false;

    try {
      final res = await _api.get('/usuarios/buscar-perfil');
      _usuario = UsuarioLogado.fromJson(res.data as Map<String, dynamic>);
      notifyListeners();
      return true;
    } catch (_) {
      await _api.deleteToken();
      return false;
    }
  }

  /// Login com email e senha.
  Future<bool> login(String email, String senha) async {
    _setLoading(true);
    _erro = null;
    try {
      final res = await _api.post(
        '/auth/login',
        data: {'email': email, 'senha': senha},
      );
      await _processarAuth(res.data as Map<String, dynamic>);
      return true;
    } on DioException catch (e) {
      _erro = _extrairErro(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registro com email e senha.
  Future<bool> registrar(String nome, String email, String senha) async {
    _setLoading(true);
    _erro = null;
    try {
      final res = await _api.post(
        '/auth/registrar',
        data: {'nome': nome, 'email': email, 'senha': senha},
      );
      await _processarAuth(res.data as Map<String, dynamic>);
      return true;
    } on DioException catch (e) {
      _erro = _extrairErro(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login / registro com Google.
  Future<bool> loginComGoogle() async {
    _setLoading(true);
    _erro = null;
    try {
      await _ensureGoogleInit();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception('Token do Google não obtido');

      final res = await _api.post('/auth/google', data: {'idToken': idToken});
      await _processarAuth(res.data as Map<String, dynamic>);
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _erro = 'Login cancelado';
      } else {
        _erro = 'Erro ao conectar com Google';
      }
      return false;
    } on DioException catch (e) {
      _erro = _extrairErro(e);
      return false;
    } catch (e) {
      _erro = 'Erro ao conectar com Google';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout.
  Future<void> logout() async {
    await _api.deleteToken();
    try {
      if (_googleSignInInitialized) await _googleSignIn.signOut();
    } catch (_) {}
    _usuario = null;
    notifyListeners();
  }

  /// Deletar conta.
  Future<bool> deletarConta() async {
    _setLoading(true);
    try {
      await _api.delete('/auth/deletar-conta');
      await logout();
      return true;
    } catch (e) {
      _erro = 'Erro ao deletar conta';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Internos ─────────────────────────────────

  Future<void> _processarAuth(Map<String, dynamic> data) async {
    await _api.saveToken(data['token'] as String);
    _usuario = UsuarioLogado.fromJson(data['usuario'] as Map<String, dynamic>);
  }

  String _extrairErro(DioException e) {
    if (e.response?.data is Map) {
      return (e.response!.data as Map)['erro'] as String? ??
          'Erro desconhecido';
    }
    return 'Erro de conexão';
  }
}
