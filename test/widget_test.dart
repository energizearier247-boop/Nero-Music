import 'package:flutter_test/flutter_test.dart';
import 'package:nero_music/main.dart';

void main() {
  testWidgets('Nero Music welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const NeroMusicApp());

    expect(find.text('NERO MUSIC'), findsOneWidget);
    expect(find.text('Your Music. Your World.'), findsOneWidget);
    expect(find.text('EXPLORE APP PREVIEW'), findsOneWidget);
  });

  testWidgets('Preview opens the main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const NeroMusicApp());
    await tester.tap(find.text('EXPLORE APP PREVIEW'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
