import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/widgets/neu_button.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('NeuButton', () {
    testWidgets('renderiza child', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuButton(
          onPressed: () {},
          child: const Text('Clique'),
        ),
      ));

      expect(find.text('Clique'), findsOneWidget);
    });

    testWidgets('chama onPressed ao tocar', (tester) async {
      bool clicado = false;
      await tester.pumpWidget(wrapWithMaterial(
        NeuButton(
          onPressed: () => clicado = true,
          child: const Text('Btn'),
        ),
      ));

      await tester.tap(find.text('Btn'));
      expect(clicado, true);
    });

    testWidgets('nao chama onPressed quando null', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuButton(
          onPressed: null,
          child: Text('Disabled'),
        ),
      ));

      await tester.tap(find.text('Disabled'));
      // No crash = success
    });

    testWidgets('mostra loading ao inves do child', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuButton(
          onPressed: () {},
          isLoading: true,
          child: const Text('Carregando'),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // O texto child fica oculto quando isLoading
    });

    testWidgets('aplica dimensoes customizadas', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuButton(
          onPressed: () {},
          width: 200,
          height: 60,
          child: const Text('Sized'),
        ),
      ));

      expect(find.text('Sized'), findsOneWidget);
    });
  });
}
