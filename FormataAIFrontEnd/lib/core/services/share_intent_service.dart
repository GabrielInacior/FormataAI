import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../stores/conversas_store.dart';
import '../../features/conversas/widgets/formato_wizard.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// MIME types e extensões aceitas como áudio válido.
const _allowedMimes = [
  'audio/',
  'video/mp4',
  'video/webm',
  'application/octet-stream',
];

const _allowedExts = [
  'm4a',
  'mp3',
  'wav',
  'aac',
  'ogg',
  'webm',
  'mp4',
  'flac',
  'opus',
  'wma',
];

/// Gerencia o recebimento de arquivos compartilhados de outros apps.
class ShareIntentService {
  ShareIntentService._();
  static final instance = ShareIntentService._();

  StreamSubscription? _sub;

  /// Inicializa a escuta de intents. Deve ser chamado uma vez após login.
  void iniciar() {
    // Arquivo compartilhado enquanto o app já estava aberto
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _processar(files),
      onError: (_) {},
    );

    // Arquivo que abriu o app
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      if (files.isNotEmpty) _processar(files);
    });
  }

  void parar() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _processar(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final file = files.first;
    final path = file.path;
    final mime = file.mimeType ?? '';
    final ext = path.split('.').last.toLowerCase();

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    // ── Validação de formato ─────────────────────────────────────────────
    final isAudio =
        _allowedMimes.any((m) => mime.startsWith(m)) ||
        _allowedExts.contains(ext);

    if (!isAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Arquivo não suportado ($ext). '
            'Compartilhe um áudio: ${_allowedExts.join(", ")}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // ── Validação de tamanho (15 MB) ─────────────────────────────────────
    try {
      final size = await File(path).length();
      if (size > 15 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Arquivo muito grande. O limite é 15 MB.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    } catch (_) {
      return;
    }

    // ── Wizard de formato ────────────────────────────────────────────────
    final formato = await mostrarFormatoWizard(context);
    if (formato == null || !context.mounted) return;

    final store = context.read<ConversasStore>();

    if (store.limiteAtingido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Limite diário de consultas atingido. Tente novamente amanhã.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // ── Criar conversa, navegar e processar ─────────────────────────────
    final conversa = await store.criarConversa();
    if (conversa == null || !context.mounted) return;

    context.go('/conversa/${conversa.id}');

    unawaited(
      store
          .processarAudio(path, conversaId: conversa.id, formato: formato)
          .catchError((e) {
        // Erro capturado aqui pois processarAudio é unawaited.
        // O store já define _erro internamente; este catch evita unhandled exception.
        debugPrint('[ShareIntent] Erro ao processar áudio compartilhado: $e');
      }),
    );

    // Marca o intent como consumido para não processar de novo
    ReceiveSharingIntent.instance.reset();
  }
}
