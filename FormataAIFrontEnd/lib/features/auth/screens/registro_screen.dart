import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/auth_store.dart';
import '../../../core/widgets/neu_container.dart';
import '../../../core/widgets/neu_text_field.dart';
import '../../../core/widgets/neu_primary_button.dart';
import '../../../core/widgets/wave_background.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthStore>();
    final ok = await auth.registrar(
      _nomeCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _senhaCtrl.text,
    );

    if (ok && mounted) {
      context.go('/home');
    } else if (mounted && auth.erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.erro!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: WaveBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone
                    NeuContainer(
                          borderRadius: 32,
                          padding: const EdgeInsets.all(24),
                          depth: 1.4,
                          child: Icon(
                            Icons.person_add_rounded,
                            size: 52,
                            color: AppColors.accent,
                          ),
                        )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 16),

                  Text(
                    'Criar Conta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  Text(
                    'Preencha seus dados para começar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 36),

                  // Nome
                  NeuTextField(
                    controller: _nomeCtrl,
                    label: 'Nome',
                    hint: 'Seu nome completo',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
                    autofillHints: const [AutofillHints.name],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Informe seu nome';
                      return null;
                    },
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                  const SizedBox(height: 18),

                  // Email
                  NeuTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'seu@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe seu email';
                      if (!v.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                  const SizedBox(height: 18),

                  // Senha
                  NeuTextField(
                    controller: _senhaCtrl,
                    label: 'Senha',
                    hint: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    obscureText: !_senhaVisivel,
                    autofillHints: const [AutofillHints.newPassword],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe uma senha';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),

                  const SizedBox(height: 18),

                  // Confirmar senha
                  NeuTextField(
                    controller: _confirmarSenhaCtrl,
                    label: 'Confirmar Senha',
                    hint: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    obscureText: !_senhaVisivel,
                    validator: (v) {
                      if (v != _senhaCtrl.text) return 'Senhas não conferem';
                      return null;
                    },
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),

                  const SizedBox(height: 32),

                  // Botão Registrar
                  Consumer<AuthStore>(
                    builder: (_, auth, __) => NeuPrimaryButton(
                      label: 'Criar Conta',
                      isLoading: auth.isLoading,
                      onPressed: _registrar,
                      icon: Icons.check_rounded,
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

                  const SizedBox(height: 28),

                  // Link login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem conta? ',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Fazer login',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
