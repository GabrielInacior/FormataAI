import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/auth_store.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/services/share_intent_service.dart';
import '../../../core/widgets/neu_container.dart';
import '../../../core/widgets/wave_background.dart';
import '../widgets/conversa_tile.dart';
import '../../conversas/widgets/gravar_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<ConversasStore>();
      store.carregarConversas();
      store.carregarEstatisticas();
      ShareIntentService.instance.iniciar();
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    ShareIntentService.instance.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthStore>();
    final store = context.watch<ConversasStore>();

    return Scaffold(
      body: Stack(
        children: [
          WaveBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // ─── Header ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, ${auth.usuario?.nome.split(' ').first ?? ''}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkText
                                          : AppColors.lightText,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Transforme áudio em texto',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/arquivadas'),
                          child: NeuContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.archive_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => context.push('/perfil'),
                          child: NeuContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),

                  const SizedBox(height: 20),

                  // ─── Busca ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: NeuContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: _buscaCtrl,
                        onChanged: (v) => store.carregarConversas(busca: v),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar conversas...',
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
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 16),

                  // ─── Lista de conversas ───────────────────
                  Expanded(
                    child: store.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : store.conversas.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            onRefresh: () => store.carregarConversas(),
                            color: AppColors.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                120,
                              ),
                              itemCount: store.conversas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final conversa = store.conversas[i];
                                return ConversaTile(
                                  conversa: conversa,
                                  onTap: () =>
                                      context.push('/conversa/${conversa.id}'),
                                  onDelete: () =>
                                      store.deletarConversa(conversa.id),
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
          Positioned(bottom: 0, left: 0, right: 0, child: const GravarButton()),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuContainer(
            borderRadius: 30,
            padding: const EdgeInsets.all(28),
            depth: 1.4,
            child: Icon(
              Icons.mic_none_rounded,
              size: 60,
              color: AppColors.accent.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma conversa ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no microfone para começar',
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
