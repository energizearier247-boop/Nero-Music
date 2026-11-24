import 'package:flutter_test/flutter_test.dart';
import 'package:nero_music/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mavtwrfjkitrgjjxgcca.supabase.co',
      publishableKey: 'sb_publishable_t9RNQkKcc6oNRR6wqrujgg_-xJnXC-M',
    );
  });

  testWidgets('Nero Music welcome screen renders', (tester) async {
    await tester.pumpWidget(const NeroMusicApp());
    expect(find.text('NERO MUSIC'), findsOneWidget);
    expect(find.text('Your Music. Your World.'), findsOneWidget);
    expect(find.text('EXPLORE APP PREVIEW'), findsOneWidget);
  });

  testWidgets('Preview opens all five main navigation destinations', (tester) async {
    await tester.pumpWidget(const NeroMusicApp());
    await tester.tap(find.text('EXPLORE APP PREVIEW'));
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Explore', 'Library', 'Earnings', 'Profile']) {
      expect(find.text(label), findsWidgets);
    }
  });
}
