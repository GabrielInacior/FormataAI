import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/widgets/neu_container.dart';
import 'package:formataai/core/theme/app_colors.dart';

void main() {
  Widget wrapWithMaterial(Widget child, {Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: child),
    );
  }

  group('NeuContainer', () {
    testWidgets('renderiza child corretamente', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuContainer(child: Text('Hello')),
      ));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('aplica borderRadius customizado', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuContainer(borderRadius: 32, child: Text('Test')),
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(32));
    });

    testWidgets('aplica width e height', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuContainer(width: 100, height: 50, child: SizedBox()),
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('isPressed muda boxShadow', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuContainer(isPressed: false, child: Text('Normal')),
      ));

      final normalContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final normalDecoration = normalContainer.decoration as BoxDecoration;
      final normalShadow = normalDecoration.boxShadow!.first;

      await tester.pumpWidget(wrapWithMaterial(
        const NeuContainer(isPressed: true, child: Text('Pressed')),
      ));
      await tester.pump(const Duration(milliseconds: 250));

      final pressedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final pressedDecoration = pressedContainer.decoration as BoxDecoration;
      final pressedShadow = pressedDecoration.boxShadow!.first;

      // Pressed has smaller blur radius
      expect(pressedShadow.blurRadius, lessThan(normalShadow.blurRadius));
    });

    testWidgets('dark theme usa cores escuras', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuContainer(child: Text('Dark')),
        brightness: Brightness.dark,
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.darkBg);
    });

    testWidgets('light theme usa cores claras', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuContainer(child: Text('Light')),
        brightness: Brightness.light,
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.lightBg);
    });
  });
}
