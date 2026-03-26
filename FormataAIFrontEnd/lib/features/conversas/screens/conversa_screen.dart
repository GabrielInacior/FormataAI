import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/widgets/wave_background.dart';
import '../../../core/widgets/neu_container.dart';
import '../widgets/gravar_button.dart';
import '../widgets/mensagem_bubble.dart';

class ConversaScreen extends StatefulWidget {
  final String conversaId;

  const ConversaScreen({super.key, required this.conversaId});

  @override
  State<ConversaScreen> createState() => _ConversaScreenState();
}

class _ConversaScreenState extends State<ConversaScreen> {
  final _scrollCtrl = ScrollController();
  int _lastItemCount = 0;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ConversasStore>().selecionarConversa(widget.conversaId);
      if (mounted) setState(() => _initialLoading = false);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollParaFim() {
    if (!mounted) return;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _compartilhar(String texto) {
    SharePlus.instance.share(ShareParams(text: texto));
  }

  void _copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copiado!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = context.watch<ConversasStore>();
    final conversa = store.conversaAtual;
    final mensagens = store.mensagens;

    final showTyping = store.isConversaProcessando(widget.conversaId) ||
        store.isAguardandoResposta(widget.conversaId);
    final totalItems = mensagens.length + (showTyping ? 1 : 0);

    // Scroll ao receber nova mensagem ou typing indicator
    if (totalItems != _lastItemCount) {
      _lastItemCount = totalItems;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollParaFim());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor:
            (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                .withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          conversa?.titulo ?? 'Conversa',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          if (conversa != null)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              onSelected: (v) async {
                if (v == 'renomear') {
                  final ctrl = TextEditingController(text: conversa.titulo);
                  final novo = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Renomear conversa'),
                      content: TextField(
                        controller: ctrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Novo nome',
                        ),
                        onSubmitted: (v) => Navigator.pop(ctx, v),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, ctrl.text),
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  );
                  if (novo != null && novo.trim().isNotEmpty && mounted) {
                    await store.atualizarConversa(conversa.id, {
                      'titulo': novo.trim(),
                    });
                    if (mounted) store.selecionarConversa(conversa.id);
                  }
                } else if (v == 'favoritar') {
                  await store.atualizarConversa(conversa.id, {
                    'favoritada': !conversa.favoritada,
                  });
                  if (mounted) store.selecionarConversa(conversa.id);
                } else if (v == 'arquivar') {
                  await store.atualizarConversa(conversa.id, {
                    'arquivada': !conversa.arquivada,
                  });
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'renomear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Renomear'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'favoritar',
                  child: Row(
                    children: [
                      Icon(
                        conversa.favoritada
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 20,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(conversa.favoritada ? 'Desfavoritar' : 'Favoritar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'arquivar',
                  child: Row(
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(conversa.arquivada ? 'Desarquivar' : 'Arquivar'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          WaveBackground(
            child: SafeArea(
              top: true,
              child: Column(
                children: [
                  // Mensagens
                  Expanded(
                    child:
                        (_initialLoading || store.isLoading)
                        ? const _VazioMensagens(processando: true)
                        : (mensagens.isEmpty &&
                            store.isConversaProcessando(widget.conversaId))
                        ? const _VazioMensagens(processando: true)
                        : mensagens.isEmpty
                        ? const _VazioMensagens()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            itemCount: totalItems,
                            itemBuilder: (_, i) {
                              if (i == mensagens.length) {
                                return const _TypingIndicator();
                              }
                              final msg = mensagens[i];
                              return MensagemBubble(
                                mensagem: msg,
                                onCopiar: () => _copiar(msg.conteudo),
                                onCompartilhar: () =>
                                    _compartilhar(msg.conteudo),
                              ).animate().fadeIn(
                                delay: Duration(milliseconds: 50 * i),
                                duration: 300.ms,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GravarButton(conversaId: widget.conversaId),
          ),
        ],
      ),
    );
  }
}

class _VazioMensagens extends StatelessWidget {
  final bool processando;
  const _VazioMensagens({this.processando = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (processando) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.92, end: 1.0, duration: 1200.ms),
            const SizedBox(height: 24),
            Text(
              'Processando seu áudio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aguarde alguns segundos...',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.record_voice_over_outlined,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Grave um áudio para começar',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }
}

/// Indicador de digitação — 3 pontinhos animados no estilo assistente.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone IA (mesmo do MensagemBubble)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? AppColors.darkShadowDark
                          : AppColors.lightShadowDark)
                      .withValues(alpha: isDark ? 0.5 : 0.8),
                  offset: const Offset(2, 2),
                  blurRadius: 5,
                ),
                BoxShadow(
                  color: (isDark
                          ? AppColors.darkShadowLight
                          : AppColors.lightShadowLight)
                      .withValues(alpha: isDark ? 0.2 : 0.8),
                  offset: const Offset(-2, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  'FormataAI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              NeuContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: const _AnimatedDots(),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// 3 pontinhos animados pulsantes.
class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 0.5,
              end: 1.0,
              delay: Duration(milliseconds: 200 * i),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            )
            .fade(
              begin: 0.3,
              end: 1.0,
              delay: Duration(milliseconds: 200 * i),
              duration: const Duration(milliseconds: 600),
            );
      }),
    );
  }
}
