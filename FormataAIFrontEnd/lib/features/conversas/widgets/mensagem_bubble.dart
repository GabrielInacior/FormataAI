import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/utils/pdf_export.dart';
import '../../../core/widgets/neu_container.dart';
import 'formato_wizard.dart';

class MensagemBubble extends StatefulWidget {
  final Mensagem mensagem;
  final VoidCallback onCopiar;
  final VoidCallback onCompartilhar;

  const MensagemBubble({
    super.key,
    required this.mensagem,
    required this.onCopiar,
    required this.onCompartilhar,
  });

  @override
  State<MensagemBubble> createState() => _MensagemBubbleState();
}

class _MensagemBubbleState extends State<MensagemBubble> {
  bool _expandido = false;
  bool? _audioDisponivel;
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Mensagem get mensagem => widget.mensagem;
  bool get _isUsuario => mensagem.tipo == 'USUARIO';

  @override
  void initState() {
    super.initState();
    if (_isUsuario && mensagem.audioUrl != null) {
      _verificarAudio();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _verificarAudio() async {
    try {
      final response = await Dio().head(mensagem.audioUrl!);
      if (mounted) {
        setState(() => _audioDisponivel = response.statusCode == 200);
      }
    } catch (_) {
      if (mounted) setState(() => _audioDisponivel = false);
    }
  }

  Future<void> _reprocessar() async {
    final formato = await mostrarFormatoWizard(context);
    if (formato == null || !mounted) return;

    final store = context.read<ConversasStore>();
    final cId = await store.reprocessarAudio(mensagem.id, formato);
    if (cId != null && mounted) {
      context.push('/conversa/$cId');
    }
  }

  Future<bool> _initPlayer() async {
    try {
      _player = AudioPlayer();
      _player!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
      _player!.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _duration = dur);
      });
      _player!.playerStateStream.listen((state) {
        if (!mounted) return;
        final playing = state.playing;
        final completed = state.processingState == ProcessingState.completed;
        setState(() => _isPlaying = playing && !completed);
        if (completed) {
          _player!.seek(Duration.zero);
          _player!.pause();
        }
      });
      await _player!.setUrl(mensagem.audioUrl!);
      return true;
    } catch (_) {
      _player?.dispose();
      _player = null;
      return false;
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_player == null) {
        final ok = await _initPlayer();
        if (!ok) return;
      }
      if (_isPlaying) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
    } catch (_) {
      // Silently handle playback errors
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: _isUsuario
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isUsuario) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(11),
                border: isDark
                    ? Border.all(
                        color: AppColors.darkShadowLight.withValues(alpha: 0.2),
                        width: 0.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color:
                        (isDark
                                ? AppColors.darkShadowDark
                                : AppColors.lightShadowDark)
                            .withValues(alpha: isDark ? 0.5 : 0.8),
                    offset: const Offset(2, 2),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color:
                        (isDark
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
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: _isUsuario
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Label
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text(
                    _isUsuario ? 'Você' : 'FormataAI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),

                // Bubble
                _isUsuario
                    ? _buildAudioCard(context, isDark)
                    : _buildAssistantBubble(context, isDark),
              ],
            ),
          ),
          if (_isUsuario) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Card de áudio para mensagens do usuário.
  Widget _buildAudioCard(BuildContext context, bool isDark) {
    final hasAudioUrl = mensagem.audioUrl != null && mensagem.audioUrl!.isNotEmpty;
    final store = context.watch<ConversasStore>();
    final isReprocessando = store.isProcessando;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: isDark ? 0.35 : 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do áudio
            GestureDetector(
              onTap: () => setState(() => _expandido = !_expandido),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão play/pause se áudio disponível, senão ícone estático
                    if (hasAudioUrl && _audioDisponivel == true)
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          hasAudioUrl
                              ? (_audioDisponivel == false
                                  ? Icons.cloud_off_rounded
                                  : Icons.graphic_eq_rounded)
                              : Icons.text_snippet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasAudioUrl
                                ? (_audioDisponivel == false
                                    ? 'Áudio indisponível'
                                    : 'Áudio enviado')
                                : 'Texto reutilizado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expandido
                                ? 'Toque para ocultar transcrição'
                                : 'Toque para ver transcrição',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expandido
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            // Player progress bar
            if (hasAudioUrl && _audioDisponivel == true && _player != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          min: 0,
                          max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                          value: _position.inMilliseconds.toDouble().clamp(
                            0,
                            _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                          ),
                          onChanged: (v) {
                            _player?.seek(Duration(milliseconds: v.toInt()));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

            // Transcrição expansível
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      height: 1,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      mensagem.transcricao ?? mensagem.conteudo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _expandido
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),

            // Botão de reutilizar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: GestureDetector(
                onTap: isReprocessando ? null : _reprocessar,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Usar em outro formato',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bubble padrão para mensagens do assistente.
  Widget _buildAssistantBubble(BuildContext context, bool isDark) {
    return NeuContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              mensagem.conteudo,
              style: TextStyle(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AcaoBtn(
                  icon: Icons.copy_rounded,
                  label: 'Copiar',
                  onTap: widget.onCopiar,
                ),
                const SizedBox(width: 12),
                _AcaoBtn(
                  icon: Icons.share_rounded,
                  label: 'Compartilhar',
                  onTap: widget.onCompartilhar,
                ),
                const SizedBox(width: 12),
                _AcaoBtn(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF',
                  onTap: () => exportarParaPdf(
                    conteudo: mensagem.conteudo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AcaoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AcaoBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
