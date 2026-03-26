import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import 'formato_wizard.dart';

class GravarButton extends StatefulWidget {
  final String? conversaId;

  const GravarButton({super.key, this.conversaId});

  @override
  State<GravarButton> createState() => _GravarButtonState();
}

class _GravarButtonState extends State<GravarButton>
    with SingleTickerProviderStateMixin {
  bool _gravando = false;
  String? _filePath;
  late AnimationController _pulseCtrl;
  Timer? _timer;
  int _segundos = 0;
  final _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    if (_gravando) _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleGravar() async {
    // Verificar limite antes de iniciar
    final store = context.read<ConversasStore>();
    if (!_gravando && store.limiteAtingido) {
      if (mounted) {
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
      }
      return;
    }

    if (_gravando) {
      await _parar();
    } else {
      await _iniciar();
    }
  }

  Future<void> _iniciar() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de microfone necessária')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/formataai_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath!,
    );

    setState(() {
      _gravando = true;
      _segundos = 0;
    });
    _pulseCtrl.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundos++);
    });
  }

  Future<void> _parar() async {
    _timer?.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    try {
      final path = await _recorder.stop();
      setState(() => _gravando = false);

      if (path == null || !mounted) return;
      _filePath = path;

      // Validar tamanho (15MB)
      final fileSize = File(_filePath!).lengthSync();
      if (fileSize > 15 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Áudio muito grande. O limite é 15MB.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Abre wizard para escolher formato
      final formato = await mostrarFormatoWizard(context);
      if (formato == null || !mounted) return; // Cancelou

      final store = context.read<ConversasStore>();

      if (widget.conversaId == null) {
        // Home: criar conversa, navegar imediatamente, processar em background
        final novaConversa = await store.criarConversa();
        if (novaConversa == null || !mounted) return;
        context.push('/conversa/${novaConversa.id}');
        unawaited(
          store.processarAudio(
            _filePath!,
            conversaId: novaConversa.id,
            formato: formato,
          ),
        );
      } else {
        // Conversa aberta: processar na conversa atual
        await store.processarAudio(
          _filePath!,
          conversaId: widget.conversaId,
          formato: formato,
        );
      }
    } catch (e) {
      setState(() => _gravando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar gravação: $e')),
        );
      }
    }
  }

  Future<void> _enviarArquivo() async {
    final store = context.read<ConversasStore>();
    if (store.limiteAtingido) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Limite diário de consultas atingido.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null || !mounted) return;

    // Validar extensão do arquivo
    final ext = result.files.single.extension?.toLowerCase() ?? '';
    final allowedExts = [
      'm4a',
      'mp3',
      'wav',
      'aac',
      'ogg',
      'webm',
      'mp4',
      'flac',
    ];
    if (!allowedExts.contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Formato não suportado. Use: ${allowedExts.join(", ")}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    // Validar tamanho (15MB)
    final fileSize = result.files.single.size;
    if (fileSize > 15 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Arquivo muito grande. O limite é 15MB.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    final formato = await mostrarFormatoWizard(context);
    if (formato == null || !mounted) return;

    try {
      if (widget.conversaId == null) {
        final novaConversa = await store.criarConversa();
        if (novaConversa == null || !mounted) return;
        context.push('/conversa/${novaConversa.id}');
        unawaited(
          store.processarAudio(
            result.files.single.path!,
            conversaId: novaConversa.id,
            formato: formato,
          ),
        );
      } else {
        await store.processarAudio(
          result.files.single.path!,
          conversaId: widget.conversaId,
          formato: formato,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar arquivo: $e')),
        );
      }
    }
  }

  String _formatarTempo(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = context.watch<ConversasStore>();
    final isProcessando = widget.conversaId != null
        ? store.isConversaProcessando(widget.conversaId!)
        : store.isProcessando;
    final limiteAtingido = store.limiteAtingido;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;

    return SizedBox(
      width: double.infinity,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ButtonWavePainter(isDark: isDark)),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Timer
        if (_gravando)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 600.ms),
                const SizedBox(width: 10),
                Text(
                  _formatarTempo(_segundos),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.3),

        // Botões: upload + gravar (mic sempre exatamente centralizado)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Botão upload de arquivo
            if (!_gravando)
              GestureDetector(
                onTap: (isProcessando || limiteAtingido)
                    ? null
                    : _enviarArquivo,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    boxShadow: [
                      BoxShadow(
                        color: shadowDark.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(3, 3),
                      ),
                      BoxShadow(
                        color: shadowLight.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(-3, -3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    color: (isProcessando || limiteAtingido)
                        ? (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                        : AppColors.accent,
                    size: 22,
                  ),
                ),
              ),

            // Espaçamento entre upload e mic
            if (!_gravando) const SizedBox(width: 16),

            // Botão neumórfico 3D (gravar)
            SizedBox(
              width: 84,
              height: 84,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  final scale = _gravando ? 1.0 + _pulseCtrl.value * 0.1 : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: GestureDetector(
                  onTap: (isProcessando || limiteAtingido)
                      ? null
                      : _toggleGravar,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _gravando
                            ? [
                                AppColors.error,
                                AppColors.error.withValues(alpha: 0.7),
                              ]
                            : [AppColors.accentLight, AppColors.accent],
                      ),
                      boxShadow: [
                        // Sombra colorida (glow)
                        BoxShadow(
                          color:
                              (_gravando ? AppColors.error : AppColors.accent)
                                  .withValues(alpha: 0.5),
                          blurRadius: _gravando ? 30 : 22,
                          offset: const Offset(0, 6),
                        ),
                        // Sombra neumórfica escura
                        BoxShadow(
                          color: shadowDark.withValues(alpha: 0.6),
                          blurRadius: 12,
                          offset: const Offset(5, 5),
                        ),
                        // Sombra neumórfica clara
                        BoxShadow(
                          color: shadowLight.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isProcessando
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : limiteAtingido
                          ? Icon(
                              Icons.block_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 38,
                            )
                          : Icon(
                              _gravando
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Espaço espelho do upload para manter mic exatamente no centro
            if (!_gravando) const SizedBox(width: 64),
          ],
        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonWavePainter extends CustomPainter {
  final bool isDark;
  _ButtonWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isDark ? AppColors.waveDark : AppColors.waveLight;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.65)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.45,
        size.width * 0.40,
        size.height * 0.45,
        size.width * 0.5,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.60,
        size.height * 0.45,
        size.width * 0.75,
        size.height * 0.45,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
