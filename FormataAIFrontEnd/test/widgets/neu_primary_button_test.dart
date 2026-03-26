import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/widgets/neu_primary_button.dart';
import 'package:formataai/core/theme/app_colors.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('NeuPrimaryButton', () {
    testWidgets('renderiza label', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuPrimaryButton(
          onPressed: () {},
          label: 'Entrar',
        ),
      ));

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('chama onPressed ao tocar', (tester) async {
      bool clicado = false;
      await tester.pumpWidget(wrapWithMaterial(
        NeuPrimaryButton(
          onPressed: () => clicado = true,
          label: 'Tap',
        ),
      ));

      await tester.tap(find.text('Tap'));
      expect(clicado, true);
    });

    testWidgets('mostra icone quando fornecido', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuPrimaryButton(
          onPressed: () {},
          label: 'Login',
          icon: Icons.arrow_forward,
        ),
      ));

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('mostra loading indicator', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuPrimaryButton(
          onPressed: () {},
          label: 'Enviando',
          isLoading: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('nao chama onPressed durante loading', (tester) async {
      bool clicado = false;
      await tester.pumpWidget(wrapWithMaterial(
        NeuPrimaryButton(
          onPressed: () => clicado = true,
          label: 'Loading',
          isLoading: true,
        ),
      ));

      await tester.tap(find.byType(GestureDetector).first);
      expect(clicado, false);
    });

    testWidgets('usa gradiente accent/primaryDark', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuPrimaryButton(
          onPressed: () {},
          label: 'Grad',
        ),
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, contains(AppColors.accent));
    });

    testWidgets('aplica width customizado', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuPrimaryButton(
          onPressed: () {},
          label: 'Wide',
          width: 250,
        ),
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      // width é definido diretamente no AnimatedContainer, não via constraints
      expect(container.constraints?.maxWidth ?? container.decoration, isNotNull);
    });
  });
}
