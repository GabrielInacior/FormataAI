import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

/// Opção de formato disponível no wizard.
class FormatoOpcao {
  final String id;
  final String nome;
  final String descricao;
  final IconData icone;

  const FormatoOpcao({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
  });
}

const _formatos = [
  FormatoOpcao(
    id: 'WHATSAPP',
    nome: 'WhatsApp',
    descricao: 'Mensagem informal e direta',
    icone: Icons.chat_rounded,
  ),
  FormatoOpcao(
    id: 'EMAIL',
    nome: 'E-mail',
    descricao: 'Texto formal com saudação',
    icone: Icons.email_rounded,
  ),
  FormatoOpcao(
    id: 'DOCUMENTO',
    nome: 'Documento',
    descricao: 'Texto estruturado e formal',
    icone: Icons.description_rounded,
  ),
  FormatoOpcao(
    id: 'ORCAMENTO',
    nome: 'Orçamento',
    descricao: 'Itens, valores e condições',
    icone: Icons.request_quote_rounded,
  ),
  FormatoOpcao(
    id: 'POSTAGEM',
    nome: 'Postagem',
    descricao: 'Post para rede social',
    icone: Icons.public_rounded,
  ),
  FormatoOpcao(
    id: 'RESUMO',
    nome: 'Resumo',
    descricao: 'Síntese objetiva e concisa',
    icone: Icons.summarize_rounded,
  ),
  FormatoOpcao(
    id: 'LISTA',
    nome: 'Lista',
    descricao: 'Tópicos organizados',
    icone: Icons.format_list_bulleted_rounded,
  ),
  FormatoOpcao(
    id: 'OUTRO',
    nome: 'Outro',
    descricao: 'Deixe a IA decidir o melhor',
    icone: Icons.auto_awesome_rounded,
  ),
];

/// Abre o wizard de formato como bottom sheet.
/// Retorna o ID do formato escolhido ou null se cancelado.
Future<String?> mostrarFormatoWizard(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FormatoWizardSheet(),
  );
}

class _FormatoWizardSheet extends StatefulWidget {
  const _FormatoWizardSheet();

  @override
  State<_FormatoWizardSheet> createState() => _FormatoWizardSheetState();
}

class _FormatoWizardSheetState extends State<_FormatoWizardSheet> {
  String? _selecionado;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: AppColors.darkShadowLight.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: secondaryText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 32,
                  color: AppColors.accent,
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 10),
                Text(
                  'Qual formato deseja?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha como quer receber o conteúdo',
                  style: TextStyle(fontSize: 14, color: secondaryText),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // Grid de formatos
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: _formatos.length,
              itemBuilder: (_, i) {
                final fmt = _formatos[i];
                final selected = _selecionado == fmt.id;
                return _FormatoCard(
                  formato: fmt,
                  selected: selected,
                  onTap: () => setState(() => _selecionado = fmt.id),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 50 * i),
                  duration: 250.ms,
                );
              },
            ),
          ),

          // Botão confirmar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: GestureDetector(
                  onTap: _selecionado != null
                      ? () => Navigator.pop(context, _selecionado)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _selecionado != null
                          ? const LinearGradient(
                              colors: [AppColors.accent, AppColors.primaryDark],
                            )
                          : null,
                      color: _selecionado == null ? surface : null,
                      boxShadow: _selecionado != null
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: _selecionado != null
                                ? Colors.white
                                : secondaryText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gerar conteúdo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selecionado != null
                                  ? Colors.white
                                  : secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatoCard extends StatelessWidget {
  final FormatoOpcao formato;
  final bool selected;
  final VoidCallback onTap;

  const _FormatoCard({
    required this.formato,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.accent, width: 2)
              : isDark
              ? Border.all(
                  color: AppColors.darkShadowLight.withValues(alpha: 0.2),
                  width: 0.5,
                )
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: shadowDark.withValues(alpha: isDark ? 0.7 : 1.0),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: shadowLight.withValues(alpha: isDark ? 0.3 : 1.0),
                    offset: const Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              formato.icone,
              size: 24,
              color: selected ? AppColors.accent : secondaryText,
            ),
            const SizedBox(height: 8),
            Text(
              formato.nome,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formato.descricao,
              style: TextStyle(fontSize: 11, color: secondaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
