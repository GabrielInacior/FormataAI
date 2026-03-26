import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/widgets/neu_container.dart';

class ConversaTile extends StatelessWidget {
  final Conversa conversa;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final IconData? deleteIcon;
  final String? deleteTooltip;

  const ConversaTile({
    super.key,
    required this.conversa,
    required this.onTap,
    required this.onDelete,
    this.deleteIcon,
    this.deleteTooltip,
  });

  IconData _iconePorCategoria(String cat) {
    return switch (cat) {
      'WHATSAPP' => Icons.chat_rounded,
      'EMAIL' => Icons.email_rounded,
      'DOCUMENTO' => Icons.description_rounded,
      'ORCAMENTO' => Icons.request_quote_rounded,
      'POSTAGEM' => Icons.public_rounded,
      'RESUMO' => Icons.summarize_rounded,
      'LISTA' => Icons.format_list_bulleted_rounded,
      'MENSAGEM' => Icons.chat_bubble_outline,
      _ => Icons.auto_awesome_rounded,
    };
  }

  String _tempoPassado(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProcessando = context.watch<ConversasStore>().isConversaProcessando(
      conversa.id,
    );

    return GestureDetector(
      onTap: onTap,
      child: NeuContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(13),
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
                            .withValues(alpha: isDark ? 0.5 : 0.7),
                    offset: const Offset(2, 2),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color:
                        (isDark
                                ? AppColors.darkShadowLight
                                : AppColors.lightShadowLight)
                            .withValues(alpha: isDark ? 0.2 : 0.7),
                    offset: const Offset(-2, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: isProcessando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Icon(
                      _iconePorCategoria(conversa.categoria),
                      color: AppColors.accent,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversa.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        conversa.categoria.toLowerCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tempoPassado(conversa.criadoEm),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (conversa.favoritada)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
            GestureDetector(
              onTap: deleteIcon != null
                  ? onDelete
                  : () => _confirmarDelete(context),
              child: Icon(
                deleteIcon ?? Icons.delete_outline,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar conversa?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
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
