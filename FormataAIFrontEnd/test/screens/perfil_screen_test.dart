import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:formataai/core/stores/auth_store.dart';
import 'package:formataai/core/stores/theme_store.dart';
import 'package:formataai/features/perfil/screens/perfil_screen.dart';

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  Widget wrapWithMaterial({
    required AuthStore authStore,
    ThemeStore? themeStore,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authStore),
        ChangeNotifierProvider(create: (_) => themeStore ?? ThemeStore()),
      ],
      child: const MaterialApp(
        home: PerfilScreen(),
      ),
    );
  }

  group('PerfilScreen', () {
    testWidgets('exibe titulo Perfil no AppBar', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('exibe botao voltar', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
    });

    testWidgets('exibe opcao tema escuro', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Tema escuro'), findsOneWidget);
    });

    testWidgets('exibe switch de tema', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('exibe opcao Sair', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('exibe opcao Deletar conta', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Deletar conta'), findsOneWidget);
    });

    testWidgets('exibe versao do app', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('FormataAI v1.0.0'), findsOneWidget);
    });

    testWidgets('exibe avatar placeholder quando sem foto', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('exibe secao Aparencia', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Aparência'), findsOneWidget);
    });

    testWidgets('exibe secao Conta', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(authStore: AuthStore()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Conta'), findsOneWidget);
    });
  });
}
