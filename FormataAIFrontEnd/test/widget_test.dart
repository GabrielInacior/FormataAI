import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:formataai/main.dart';

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const FormataAIApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('FormataAI'), findsAny);
  });
}
