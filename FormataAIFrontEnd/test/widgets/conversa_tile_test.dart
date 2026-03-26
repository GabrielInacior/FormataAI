import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/stores/conversas_store.dart';
import 'package:formataai/features/home/widgets/conversa_tile.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  final conversa = Conversa(
    id: 'conv-1',
    titulo: 'Aula de história',
    categoria: 'ACADEMICO',
    favoritada: false,
    arquivada: false,
    criadoEm: DateTime.now().subtract(const Duration(hours: 2)),
  );

  group('ConversaTile', () {
    testWidgets('exibe titulo da conversa', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.text('Aula de história'), findsOneWidget);
    });

    testWidgets('exibe categoria em lowercase', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.text('academico'), findsOneWidget);
    });

    testWidgets('exibe icone por categoria ACADEMICO', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('chama onTap ao tocar', (tester) async {
      bool tocado = false;
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () => tocado = true,
          onDelete: () {},
        ),
      ));

      await tester.tap(find.text('Aula de história'));
      expect(tocado, true);
    });

    testWidgets('exibe estrela quando favoritada', (tester) async {
      final fav = Conversa(
        id: 'conv-fav',
        titulo: 'Favorita',
        categoria: 'PESSOAL',
        favoritada: true,
        arquivada: false,
        criadoEm: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: fav,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('nao exibe estrela quando nao favoritada', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('botao delete abre dialog de confirmacao', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Deletar conversa?'), findsOneWidget);
      expect(find.text('Esta ação não pode ser desfeita.'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Deletar'), findsOneWidget);
    });

    testWidgets('cancelar dialog nao chama onDelete', (tester) async {
      bool deletado = false;
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () {},
          onDelete: () => deletado = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(deletado, false);
    });

    testWidgets('confirmar delete chama onDelete', (tester) async {
      bool deletado = false;
      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: conversa,
          onTap: () {},
          onDelete: () => deletado = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deletar'));
      await tester.pumpAndSettle();

      expect(deletado, true);
    });

    testWidgets('exibe tempo passado recente', (tester) async {
      final recentConv = Conversa(
        id: 'conv-recent',
        titulo: 'Recente',
        categoria: 'OUTRO',
        favoritada: false,
        arquivada: false,
        criadoEm: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: recentConv,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.text('5min'), findsOneWidget);
    });

    testWidgets('icone PROFISSIONAL', (tester) async {
      final profConv = Conversa(
        id: 'conv-prof',
        titulo: 'Trabalho',
        categoria: 'PROFISSIONAL',
        favoritada: false,
        arquivada: false,
        criadoEm: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithMaterial(
        ConversaTile(
          conversa: profConv,
          onTap: () {},
          onDelete: () {},
        ),
      ));

      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });
  });
}
