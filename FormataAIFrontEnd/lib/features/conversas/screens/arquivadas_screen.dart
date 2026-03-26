import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/widgets/neu_container.dart';
import '../../../core/widgets/wave_background.dart';
import '../../home/widgets/conversa_tile.dart';

class ArquivadasScreen extends StatefulWidget {
  const ArquivadasScreen({super.key});

  @override
  State<ArquivadasScreen> createState() => _ArquivadasScreenState();
}

class _ArquivadasScreenState extends State<ArquivadasScreen> {
  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversasStore>().carregarArquivadas();
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = context.watch<ConversasStore>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conversas Arquivadas',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: WaveBackground(
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              // ─── Busca ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: NeuContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _buscaCtrl,
                    onChanged: (v) => store.carregarArquivadas(busca: v),
                    style: TextStyle(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar arquivadas...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: AppColors.primary),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),

              // ─── Lista ────────────────────────────────
              Expanded(
                child: store.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : store.arquivadas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.archive_outlined,
                                  size: 60,
                                  color: AppColors.accent.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma conversa arquivada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 400.ms),
                          )
                        : RefreshIndicator(
                            onRefresh: () => store.carregarArquivadas(),
                            color: AppColors.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: store.arquivadas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final conversa = store.arquivadas[i];
                                return ConversaTile(
                                  conversa: conversa,
                                  onTap: () =>
                                      context.push('/conversa/${conversa.id}'),
                                  onDelete: () async {
                                    await store.atualizarConversa(
                                      conversa.id,
                                      {'arquivada': false},
                                    );
                                    store.carregarArquivadas();
                                  },
                                  deleteIcon: Icons.unarchive_rounded,
                                  deleteTooltip: 'Desarquivar',
                                ).animate().fadeIn(
                                  delay: Duration(milliseconds: 50 * i),
                                  duration: 300.ms,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
