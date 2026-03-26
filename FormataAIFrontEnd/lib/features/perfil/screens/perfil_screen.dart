import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/auth_store.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/stores/theme_store.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/neu_container.dart';
import '../../../core/widgets/wave_background.dart';
import '../../home/widgets/stats_card.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversasStore>().carregarEstatisticas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthStore>();
    final theme = context.watch<ThemeStore>();
    final conversasStore = context.watch<ConversasStore>();
    final usuario = auth.usuario;

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
          'Perfil',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: WaveBackground(
        child: SafeArea(
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                // ─── Avatar ─────────────────────────────
                NeuContainer(
                      borderRadius: 50,
                      padding: const EdgeInsets.all(4),
                      depth: 1.3,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.15,
                        ),
                        backgroundImage: usuario?.fotoUrl != null
                            ? NetworkImage(usuario!.fotoUrl!)
                            : null,
                        child: usuario?.fotoUrl == null
                            ? Text(
                                usuario?.nome.isNotEmpty == true
                                    ? usuario!.nome[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              )
                            : null,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 14),

                Text(
                  usuario?.nome ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                Text(
                  usuario?.email ?? '',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                if (usuario?.provedor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        usuario!.provedor,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                // ─── Uso / Estatísticas ─────────────────
                if (conversasStore.estatisticas != null)
                  StatsCard(
                    stats: conversasStore.estatisticas!,
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // ─── Opções ─────────────────────────────
                _Secao(
                  titulo: 'Aparência',
                  children: [
                    _OpcaoTile(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      titulo: 'Tema escuro',
                      trailing: Switch.adaptive(
                        value: theme.isDark,
                        onChanged: (_) => theme.toggle(),
                        activeTrackColor: AppColors.accent,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                _Secao(
                  titulo: 'Conta',
                  children: [
                    if (usuario?.provedor == 'EMAIL')
                      _OpcaoTile(
                        icon: Icons.lock_outline,
                        titulo: 'Alterar senha',
                        onTap: () => _alterarSenha(context),
                      ),
                    _OpcaoTile(
                      icon: Icons.logout_rounded,
                      titulo: 'Sair',
                      cor: AppColors.warning,
                      onTap: () => _logout(context),
                    ),
                    _OpcaoTile(
                      icon: Icons.delete_forever_outlined,
                      titulo: 'Deletar conta',
                      cor: AppColors.error,
                      onTap: () => _deletarConta(context),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                Text(
                  'FormataAI v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _alterarSenha(BuildContext context) {
    final senhaAtualCtrl = TextEditingController();
    final novaSenhaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Alterar Senha',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: senhaAtualCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: novaSenhaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ApiService.instance.put(
                      '/auth/alterar-senha',
                      data: {
                        'senhaAtual': senhaAtualCtrl.text,
                        'novaSenha': novaSenhaCtrl.text,
                      },
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Senha alterada com sucesso!'),
                        ),
                      );
                    }
                  } catch (_) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro ao alterar senha')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthStore>().logout();
              context.go('/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  void _deletarConta(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar Conta'),
        content: const Text(
          'Esta ação é irreversível. Todos os seus dados serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<AuthStore>().deletarConta();
              if (ok && context.mounted) context.go('/login');
            },
            child: const Text(
              'Deletar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Secao({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        NeuContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _OpcaoTile extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? cor;

  const _OpcaoTile({
    required this.icon,
    required this.titulo,
    this.trailing,
    this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = cor ?? (isDark ? AppColors.darkText : AppColors.lightText);

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        titulo,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5))
              : null),
      onTap: onTap,
    );
  }
}
