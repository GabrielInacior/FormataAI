import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/stores/conversas_store.dart';
import 'package:formataai/features/conversas/widgets/mensagem_bubble.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: child,
        ),
      ),
    );
  }

  group('MensagemBubble', () {
    testWidgets('mensagem USUARIO alinhada a direita', (tester) async {
      final msg = Mensagem(
        id: 'msg-1',
        tipo: 'USUARIO',
        conteudo: 'Olá mundo',
        criadoEm: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithMaterial(
        MensagemBubble(
          mensagem: msg,
          onCopiar: () {},
          onCompartilhar: () {},
        ),
      ));

      expect(find.text('Olá mundo'), findsOneWidget);
      expect(find.text('Você'), findsOneWidget);
    });

    testWidgets('mensagem ASSISTENTE mostra icone e acoes', (tester) async {
      final msg = Mensagem(
        id: 'msg-2',
        tipo: 'ASSISTENTE',
        conteudo: 'Texto formatado pela IA',
        criadoEm: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithMaterial(
        MensagemBubble(
          mensagem: msg,
          onCopiar: () {},
          onCompartilhar: () {},
        ),
      ));

      expect(find.text('Texto formatado pela IA'), findsOneWidget);
      expect(find.text('FormataAI'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
    });

    testWidgets('botao copiar chama callback', (tester) async {
      bool copiado = false;
      final msg = Mensagem(
        id: 'msg-3',
        tipo: 'ASSISTENTE',
        conteudo: 'Copie-me',
        criadoEm: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithMaterial(
        MensagemBubble(
          mensagem: msg,
          onCopiar: () => copiado = true,
          onCompartilhar: () {},
        ),
      ));

      await tester.tap(find.text('Copiar'));
      expect(copiado, true);
    });

    testWidgets('botao compartilhar chama callback', (tester) async {
      bool compartilhado = false;
      final msg = Mensagem(
        id: 'msg-4',
        tipo: 'ASSISTENTE',
        conteudo: 'Compartilhe-me',
        criadoEm: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithMaterial(
        MensagemBubble(
          mensagem: msg,
          onCopiar: () {},
          onCompartilhar: () => compartilhado = true,
        ),
      ));

      await tester.tap(find.text('Compartilhar'));
      expect(compartilhado, true);
    });

    testWidgets('mensagem USUARIO nao mostra botoes de acao', (tester) async {
      final msg = Mensagem(
        id: 'msg-5',
        tipo: 'USUARIO',
        conteudo: 'Minha mensagem',
        criadoEm: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithMaterial(
        MensagemBubble(
          mensagem: msg,
          onCopiar: () {},
          onCompartilhar: () {},
        ),
      ));

      expect(find.text('Copiar'), findsNothing);
      expect(find.text('Compartilhar'), findsNothing);
    });
  });
}
