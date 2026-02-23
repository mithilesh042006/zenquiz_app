import 'package:flutter_test/flutter_test.dart';
import 'package:zenquiz/app.dart';

void main() {
  testWidgets('App builds and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZenQuizApp());

    // Verify that the home screen renders with expectedUI elements.
    expect(find.text('ZenQuiz'), findsWidgets);
  });
}
