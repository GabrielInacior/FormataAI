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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthStore>();
    final ok = await auth.login(_emailCtrl.text.trim(), _senhaCtrl.text);

    if (ok && mounted) {
      context.go('/home');
    } else if (mounted && auth.erro != null) {
      _mostrarErro(auth.erro!);
    }
  }

  Future<void> _loginGoogle() async {
    final auth = context.read<AuthStore>();
    final ok = await auth.loginComGoogle();

    if (ok && mounted) {
      context.go('/home');
    } else if (mounted && auth.erro != null) {
      _mostrarErro(auth.erro!);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                    // Logo
                    NeuContainer(
                          borderRadius: 32,
                          padding: const EdgeInsets.all(2),
                          depth: 1.4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/Icon.png',
                              width: 130,
                              height: 130,
                            ),
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
                      'FormataAI',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    Text(
                      'Transforme áudio em texto formatado',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 40),

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
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                    const SizedBox(height: 20),

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
                      autofillHints: const [AutofillHints.password],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.primary,
                        ),
                        onPressed: () =>
                            setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe sua senha';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                    const SizedBox(height: 32),

                    // Botão Entrar
                    Consumer<AuthStore>(
                      builder: (_, auth, __) => NeuPrimaryButton(
                        label: 'Entrar',
                        isLoading: auth.isLoading,
                        onPressed: _fazerLogin,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkShadowLight
                                : AppColors.lightShadowDark,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkShadowLight
                                : AppColors.lightShadowDark,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 20),

                    // Google
                    Consumer<AuthStore>(
                      builder: (_, auth, __) => _GoogleButton(
                        isLoading: auth.isLoading,
                        onPressed: _loginGoogle,
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

                    const SizedBox(height: 32),

                    // Link registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem conta? ',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/registro'),
                          child: Text(
                            'Criar conta',
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

class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleButton({required this.isLoading, required this.onPressed});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: isDark
                        ? AppColors.darkShadowDark
                        : AppColors.lightShadowDark,
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: isDark
                        ? AppColors.darkShadowLight
                        : AppColors.lightShadowLight,
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: widget.isLoading
            ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 24,
                    width: 24,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continuar com Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
