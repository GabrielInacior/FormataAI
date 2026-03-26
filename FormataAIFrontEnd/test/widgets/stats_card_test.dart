import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/stores/conversas_store.dart';
import 'package:formataai/features/home/widgets/stats_card.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('StatsCard', () {
    testWidgets('exibe plano', (tester) async {
      final stats = Estatisticas(
        consultasUsadas: 5,
        limiteConsultas: 50,
        consultasRestantes: 45,
        plano: 'GRATUITO',
      );

      await tester.pumpWidget(wrapWithMaterial(StatsCard(stats: stats)));

      expect(find.text('GRATUITO'), findsOneWidget);
    });

    testWidgets('exibe consultas restantes', (tester) async {
      final stats = Estatisticas(
        consultasUsadas: 10,
        limiteConsultas: 50,
        consultasRestantes: 40,
        plano: 'PRO',
      );

      await tester.pumpWidget(wrapWithMaterial(StatsCard(stats: stats)));

      expect(find.text('40 restantes'), findsOneWidget);
    });

    testWidgets('exibe progresso', (tester) async {
      final stats = Estatisticas(
        consultasUsadas: 25,
        limiteConsultas: 50,
        consultasRestantes: 25,
        plano: 'GRATUITO',
      );

      await tester.pumpWidget(wrapWithMaterial(StatsCard(stats: stats)));

      expect(find.text('25 de 50 consultas usadas'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progresso zerado se limiteConsultas 0', (tester) async {
      final stats = Estatisticas(
        consultasUsadas: 0,
        limiteConsultas: 0,
        consultasRestantes: 0,
        plano: 'FREE',
      );

      await tester.pumpWidget(wrapWithMaterial(StatsCard(stats: stats)));

      expect(find.text('0 de 0 consultas usadas'), findsOneWidget);
    });
  });
}
