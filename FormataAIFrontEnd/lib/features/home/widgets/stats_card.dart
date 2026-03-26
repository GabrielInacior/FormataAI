import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/stores/conversas_store.dart';
import '../../../core/widgets/neu_container.dart';

class StatsCard extends StatelessWidget {
  final Estatisticas stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = stats.limiteConsultas > 0
        ? stats.consultasUsadas / stats.limiteConsultas
        : 0.0;

    return NeuContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      depth: 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  stats.plano,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${stats.consultasRestantes} restantes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark
                  ? AppColors.darkShadowDark.withValues(alpha: 0.8)
                  : AppColors.lightShadowDark.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation(
                pct > 0.8 ? AppColors.error : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.consultasUsadas} de ${stats.limiteConsultas} consultas usadas',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
