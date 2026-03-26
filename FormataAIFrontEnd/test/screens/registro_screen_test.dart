import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:formataai/core/stores/auth_store.dart';
import 'package:formataai/core/stores/theme_store.dart';
import 'package:formataai/core/stores/conversas_store.dart';
import 'package:formataai/core/widgets/neu_text_field.dart';
import 'package:formataai/features/auth/screens/registro_screen.dart';

Widget _buildTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeStore()),
      ChangeNotifierProvider(create: (_) => AuthStore()),
      ChangeNotifierProvider(create: (_) => ConversasStore()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  group('RegistroScreen', () {
    testWidgets('renderiza titulo Criar Conta', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Criar Conta'), findsAtLeast(1));
    });

    testWidgets('renderiza subtitulo', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Preencha seus dados para começar'), findsOneWidget);
    });

    testWidgets('renderiza 4 campos de texto', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(NeuTextField), findsNWidgets(4));
    });

    testWidgets('renderiza link para login', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Já tem conta? '), findsOneWidget);
      expect(find.text('Fazer login'), findsOneWidget);
    });

    testWidgets('icone person_add_rounded', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
    });

    testWidgets('validacao nome vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      final botao = find.text('Criar Conta');
      await tester.tap(botao.last);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Informe seu nome'), findsOneWidget);
    });

    testWidgets('validacao senhas diferentes', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'test@email.com');
      await tester.enterText(fields.at(2), 'senha123');
      await tester.enterText(fields.at(3), 'outrasenha');

      final botao = find.text('Criar Conta');
      await tester.tap(botao.last);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Senhas não conferem'), findsOneWidget);
    });

    testWidgets('validacao email invalido', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test');
      await tester.enterText(fields.at(1), 'invalido');

      final botao = find.text('Criar Conta');
      await tester.tap(botao.last);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('toggle visibilidade da senha', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RegistroScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
