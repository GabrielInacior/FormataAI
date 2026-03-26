import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/widgets/wave_background.dart';
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
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversasStore>().selecionarConversa(widget.conversaId);
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

    // Scroll ao receber nova mensagem (só quando a contagem muda)
    if (mensagens.length != _lastMsgCount) {
      _lastMsgCount = mensagens.length;
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
                if (v == 'favoritar') {
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
                  // Banner de processamento — visível e amigável
                  if (store.isConversaProcessando(widget.conversaId))
                    _ProcessandoBanner(isDark: isDark),

                  // Mensagens
                  Expanded(
                    child: store.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : mensagens.isEmpty
                        ? _VazioMensagens(
                            processando: store.isConversaProcessando(
                              widget.conversaId,
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            itemCount: mensagens.length,
                            itemBuilder: (_, i) {
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

class _ProcessandoBanner extends StatefulWidget {
  final bool isDark;
  const _ProcessandoBanner({required this.isDark});

  @override
  State<_ProcessandoBanner> createState() => _ProcessandoBannerState();
}

class _ProcessandoBannerState extends State<_ProcessandoBanner> {
  int _etapa = 0;
  late final List<String> _etapas;

  @override
  void initState() {
    super.initState();
    _etapas = [
      '🎙️ Transcrevendo seu áudio...',
      '🤖 Formatando o conteúdo...',
      '✨ Finalizando...',
    ];
    _avancarEtapa();
  }

  void _avancarEtapa() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _etapa = (_etapa + 1).clamp(0, _etapas.length - 1));
      if (_etapa < _etapas.length - 1) _avancarEtapa();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _etapas[_etapa],
                key: ValueKey(_etapa),
                style: TextStyle(
                  color: widget.isDark
                      ? AppColors.darkText
                      : AppColors.lightText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
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
