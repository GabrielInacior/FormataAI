import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/widgets/neu_container.dart';

class MensagemBubble extends StatelessWidget {
  final Mensagem mensagem;
  final VoidCallback onCopiar;
  final VoidCallback onCompartilhar;

  const MensagemBubble({
    super.key,
    required this.mensagem,
    required this.onCopiar,
    required this.onCompartilhar,
  });

  bool get _isUsuario => mensagem.tipo == 'USUARIO';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: _isUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                    ? Border.all(color: AppColors.darkShadowLight.withValues(alpha: 0.2), width: 0.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark)
                        .withValues(alpha: isDark ? 0.5 : 0.8),
                    offset: const Offset(2, 2),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: (isDark ? AppColors.darkShadowLight : AppColors.lightShadowLight)
                        .withValues(alpha: isDark ? 0.2 : 0.8),
                    offset: const Offset(-2, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: _isUsuario ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Label
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text(
                    _isUsuario ? 'Você' : 'FormataAI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),

                // Bubble
                _isUsuario
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
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
                        child: Text(
                          mensagem.conteudo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      )
                    : NeuContainer(
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
                                    onTap: onCopiar,
                                  ),
                                  const SizedBox(width: 12),
                                  _AcaoBtn(
                                    icon: Icons.share_rounded,
                                    label: 'Compartilhar',
                                    onTap: onCompartilhar,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
          if (_isUsuario) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _AcaoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AcaoBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
