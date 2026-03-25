import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeokjangnim/main.dart' show YeokjangApp;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // LoginScreen 등에서 Supabase.instance를 쓰므로, 스플래시 이후 프레임을 pump하기 전에 초기화
    await Supabase.initialize(
      url: 'https://qbfoomdzdssspkvbpdev.supabase.co',
      anonKey: 'sb_publishable_TsNqH8MaqBfqvsg16oACvw_wtvLdIsk',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  });

  testWidgets('YeokjangApp builds (splash → 로그인)', (tester) async {
    await tester.pumpWidget(const YeokjangApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('철도 마스터'), findsOneWidget);
    // SplashScreen의 Future.delayed(2.2s) 소비
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('이메일로 시작하기'), findsOneWidget);
  });
}
