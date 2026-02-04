import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';

void main() {
  testWidgets('Navigation from HomePage to SelectCity works', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Check if HomePage loaded
    expect(find.text('Get Started'), findsOneWidget);

    // Tap the Get Started button
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Check if navigated to SelectCity page
    expect(find.text('Weather Vibe'), findsOneWidget);
  });
}
