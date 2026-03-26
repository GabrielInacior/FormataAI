import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:formataai/core/stores/auth_store.dart';
import 'package:formataai/core/stores/theme_store.dart';
import 'package:formataai/core/stores/conversas_store.dart';
import 'package:formataai/core/widgets/neu_text_field.dart';
import 'package:formataai/core/widgets/neu_primary_button.dart';
import 'package:formataai/features/auth/screens/login_screen.dart';

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
  // Desabilita animações do flutter_animate nos testes
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  group('LoginScreen', () {
    testWidgets('renderiza campos de email e senha', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(NeuTextField), findsAtLeast(2));
    });

    testWidgets('renderiza botao Entrar', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('renderiza titulo FormataAI', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('FormataAI'), findsOneWidget);
    });

    testWidgets('renderiza subtitulo', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Transforme áudio em texto formatado'), findsOneWidget);
    });

    testWidgets('renderiza link para registro', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Não tem conta? '), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('renderiza botao Google', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Continuar com Google'), findsOneWidget);
    });

    testWidgets('renderiza separador "ou"', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('ou'), findsOneWidget);
    });

    testWidgets('validacao email vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Entrar'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Informe seu email'), findsOneWidget);
    });

    testWidgets('validacao senha vazia', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@email.com');

      await tester.tap(find.text('Entrar'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Informe sua senha'), findsOneWidget);
    });

    testWidgets('validacao email invalido', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'emailsemat');

      await tester.tap(find.text('Entrar'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('validacao senha curta', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@email.com');
      await tester.enterText(fields.at(1), '123');

      await tester.tap(find.text('Entrar'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('toggle visibilidade da senha', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('icone decorativo auto_awesome', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}
