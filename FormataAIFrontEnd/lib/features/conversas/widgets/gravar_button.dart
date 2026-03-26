import 'dart:async';
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

      // Abre wizard para escolher formato
      final formato = await mostrarFormatoWizard(context);
      if (formato == null || !mounted) return; // Cancelou

      final store = context.read<ConversasStore>();
      final cId = await store.processarAudio(
        _filePath!,
        conversaId: widget.conversaId,
        formato: formato,
      );

      // Se gravou da home (sem conversaId), navega pra conversa criada
      if (widget.conversaId == null && cId != null && mounted) {
        context.push('/conversa/$cId');
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

  String _formatarTempo(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProcessando = context.watch<ConversasStore>().isProcessando;
    final shadowDark = isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark;
    final shadowLight = isDark ? AppColors.darkShadowLight : AppColors.lightShadowLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
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

        // Botão neumórfico 3D
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
              onTap: isProcessando ? null : _toggleGravar,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _gravando
                        ? [AppColors.error, AppColors.error.withValues(alpha: 0.7)]
                        : [AppColors.accentLight, AppColors.accent],
                  ),
                  boxShadow: [
                    // Sombra colorida (glow)
                    BoxShadow(
                      color: (_gravando ? AppColors.error : AppColors.accent)
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
                      : Icon(
                          _gravando ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
