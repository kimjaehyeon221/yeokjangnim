import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeokjangnim/app_state.dart';
import 'package:yeokjangnim/main.dart' show YeokjangApp;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://qbfoomdzdssspkvbpdev.supabase.co',
      anonKey: 'sb_publishable_TsNqH8MaqBfqvsg16oACvw_wtvLdIsk',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  });

  testWidgets('YeokjangApp renders splash screen', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const YeokjangApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('지하철도 999'), findsOneWidget);
    // Drain splash minSplash timer; animation is repeating so avoid pumpAndSettle
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
  });
}
