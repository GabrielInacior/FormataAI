import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

/// Serviço HTTP centralizado — injeta token JWT automaticamente.
class ApiService {
  ApiService._() : _storage = const FlutterSecureStorage(), _dio = Dio() {
    _configurarDio();
  }

  static final instance = ApiService._();

  /// Construtor para testes — aceita Dio e Storage personalizados.
  ApiService.test(this._dio, this._storage);

  final FlutterSecureStorage _storage;
  final Dio _dio;

  static const _tokenKey = 'auth_token';

  void _configurarDio() {
    final baseUrl = !kIsWeb && Platform.isAndroid
        ? kApiBaseUrlAndroid
        : kApiBaseUrlDefault;

    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  // ─── Token management ─────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  // ─── HTTP methods ─────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> upload(
    String path, {
    required String filePath,
    String fieldName = 'audio',
    Map<String, dynamic>? extraFields,
  }) {
    final map = <String, dynamic>{
      fieldName: MultipartFile.fromFileSync(filePath),
    };
    if (extraFields != null) map.addAll(extraFields);
    final formData = FormData.fromMap(map);
    return _dio.post(
      path,
      data: formData,
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
  }
}
