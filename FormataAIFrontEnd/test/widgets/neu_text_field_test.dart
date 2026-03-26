import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formataai/core/widgets/neu_text_field.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }

  group('NeuTextField', () {
    testWidgets('renderiza com hint', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuTextField(hint: 'Digite algo'),
      ));

      expect(find.text('Digite algo'), findsOneWidget);
    });

    testWidgets('renderiza com label', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuTextField(label: 'Email'),
      ));

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('aceita input de texto', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(wrapWithMaterial(
        NeuTextField(controller: controller, hint: 'Input'),
      ));

      await tester.enterText(find.byType(TextFormField), 'teste@email.com');
      expect(controller.text, 'teste@email.com');
    });

    testWidgets('chama onChanged ao digitar', (tester) async {
      String? valorRecebido;
      await tester.pumpWidget(wrapWithMaterial(
        NeuTextField(
          hint: 'Type',
          onChanged: (v) => valorRecebido = v,
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'abc');
      expect(valorRecebido, 'abc');
    });

    testWidgets('obscureText esconde texto', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuTextField(hint: 'Senha', obscureText: true),
      ));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, true);
    });

    testWidgets('exibe prefixIcon', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const NeuTextField(
          hint: 'Email',
          prefixIcon: Icon(Icons.email),
        ),
      ));

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('exibe suffixIcon', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        NeuTextField(
          hint: 'Senha',
          suffixIcon: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('validator mostra erro', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapWithMaterial(
        Form(
          key: formKey,
          child: NeuTextField(
            hint: 'Email',
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obrigatório';
              return null;
            },
          ),
        ),
      ));

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsOneWidget);
    });
  });
}
