import 'package:flutter_test/flutter_test.dart';
import 'package:ikigabo/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const IkigaboApp());
    expect(find.byType(IkigaboApp), findsOneWidget);
  });
}
