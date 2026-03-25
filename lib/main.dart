import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'models.dart';
import 'app_state.dart';
import 'open_external_url.dart';

const kPrivacyPolicyUrl = 'https://kimjaehyeon221.github.io/yeokjangnim/privacy-policy.html';
const kTermsUrl = 'https://kimjaehyeon221.github.io/yeokjangnim/terms.html';

Future<void> _shareCollectionProgress(BuildContext context, AppState state) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _CollectionShareDialog(state: state),
  );
}

/// 도감 공유 — 텍스트 복사·이미지 공유가 항상 보이도록 다이얼로그로 제공.
class _CollectionShareDialog extends StatefulWidget {
  final AppState state;
  const _CollectionShareDialog({required this.state});

  @override
  State<_CollectionShareDialog> createState() => _CollectionShareDialogState();
}

class _CollectionShareDialogState extends State<_CollectionShareDialog> {
  final GlobalKey _cardKey = GlobalKey();

  String get _shareText {
    final got = widget.state.gotCount;
    final total = widget.state.totalStations;
    return '철도 마스터에서 전국 역 스탬프 $got / $total개 모았어요! 🚉';
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사했어요.')));
  }

  Future<void> _shareImage() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final xf = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'cheoldo_master_stamps.png',
      );
      await Share.shareXFiles([xf], text: _shareText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 공유에 실패했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final got = widget.state.gotCount;
    final total = widget.state.totalStations;
    final pct = total > 0 ? got / total : 0.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AC.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AC.stamp, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x331B3A6B), blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    const Text('철도 마스터', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AC.stamp, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(widget.state.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AC.ink)),
                    const SizedBox(height: 16),
                    Text('$got / $total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AC.stamp, letterSpacing: -1)),
                    Text('전국 역 스탬프', style: TextStyle(fontSize: 11, color: AC.ink3)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AC.paper2, color: AC.stamp),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(_shareText, style: const TextStyle(fontSize: 12, color: AC.ink2, height: 1.4)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _copyText,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AC.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('텍스트 복사', style: TextStyle(fontWeight: FontWeight.w700, color: AC.ink2)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _shareImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AC.stamp,
                      foregroundColor: AC.paper,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('이미지 공유', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: AC.ink3)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('회원 탈퇴'),
      content: const Text(
        '스탬프·뱃지·프로필 등 계정과 연동된 데이터가 모두 삭제되며 되돌릴 수 없어요.\n정말 탈퇴할까요?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('탈퇴', style: TextStyle(color: Colors.red.shade700)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final msg = await context.read<AppState>().deleteOwnAccount();
  if (!context.mounted) return;
  if (msg != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    return;
  }
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Supabase.initialize(
    url: 'https://qbfoomdzdssspkvbpdev.supabase.co',
    anonKey: 'sb_publishable_TsNqH8MaqBfqvsg16oACvw_wtvLdIsk',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const YeokjangApp(),
    ),
  );
}

class AC {
  static const paper   = Color(0xFFF5F0E8);
  static const paper2  = Color(0xFFEDE8DC);
  static const paper3  = Color(0xFFE0D9CC);
  static const ink     = Color(0xFF1A1510);
  static const ink2    = Color(0xFF3D342A);
  static const ink3    = Color(0xFF7A6E62);
  static const ink4    = Color(0xFFB8AFA3);
  static const stamp   = Color(0xFF1B3A6B);
  static const stampDim = Color(0x1A1B3A6B);
  static const gold    = Color(0xFF8B6914);
  static const goldDim = Color(0x1F8B6914);
  static const border  = Color(0x1A1A1510);
}

class YeokjangApp extends StatelessWidget {
  const YeokjangApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '철도 마스터',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: AC.paper,
        colorScheme: const ColorScheme.light(primary: AC.stamp, surface: AC.paper),
        appBarTheme: const AppBarTheme(
          backgroundColor: AC.paper,
          foregroundColor: AC.ink,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AC.ink),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ══ 스플래시 ══════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}
class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.stamp,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(animation: _c, builder: (_, child) =>
        Transform.translate(offset: Offset(Tween(begin: 0.0, end: 5.0).evaluate(_c), 0), child: child),
        child: const Text('🚇', style: TextStyle(fontSize: 80))),
      const SizedBox(height: 20),
      const Text('철도 마스터', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: AC.paper, letterSpacing: -2)),
      const SizedBox(height: 8),
      Text('전국 역을 모두 모아봐요', style: TextStyle(fontSize: 13, color: AC.paper.withValues(alpha: 0.4), letterSpacing: 3)),
    ])),
  );
}

// ══ 로그인 ════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      final event = data.event;
      final session = data.session;
      if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) && session != null) {
        final state = context.read<AppState>();
        state.userId = session.user.id;
        await state.retryPendingStamps();
        await state.syncProfileFromRemote();
        if (!mounted) return;
        if (state.profileReady) {
          _goMain(context);
        } else {
          _goNickname(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _goMain(BuildContext ctx) => Navigator.pushReplacement(
        ctx,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );

  void _goNickname(BuildContext ctx) => Navigator.pushReplacement(
        ctx,
        MaterialPageRoute(builder: (_) => const NicknameScreen()),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.stamp,
    body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(children: [
      const Spacer(),
      const Text('🚇', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('철도 마스터', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AC.paper, letterSpacing: -2)),
      const SizedBox(height: 8),
      Text('전국 역을 모두 모아봐요', style: TextStyle(fontSize: 13, color: AC.paper.withValues(alpha: 0.4), letterSpacing: 2)),
      const Spacer(),
      _SocialBtn(
        color: AC.paper2,
        textColor: AC.ink2,
        label: '이메일로 시작하기',
        emoji: '✉️',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
        ),
      ),
      const SizedBox(height: 20),
      Text('계속 진행하면 서비스 이용약관 및\n개인정보처리방침에 동의한 것으로 간주돼요',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AC.paper.withValues(alpha: 0.3), height: 1.7)),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => openExternalUrl(context, kTermsUrl),
            child: Text(
              '서비스 이용약관',
              style: TextStyle(
                fontSize: 11,
                color: AC.paper.withValues(alpha: 0.8),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Text('·', style: TextStyle(color: AC.paper.withValues(alpha: 0.6))),
          TextButton(
            onPressed: () => openExternalUrl(context, kPrivacyPolicyUrl),
            child: Text(
              '개인정보처리방침',
              style: TextStyle(
                fontSize: 11,
                color: AC.paper.withValues(alpha: 0.8),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
    ]))),
  );
}

class _SocialBtn extends StatelessWidget {
  final Color color, textColor;
  final String label, emoji;
  final VoidCallback onTap;
  const _SocialBtn({required this.color, required this.textColor, required this.label, required this.emoji, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity,
    child: ElevatedButton(onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
      ])));
}

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});
  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signupMode = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _email.text.trim();
    final pw = _password.text.trim();
    if (email.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    final msg = _signupMode
        ? await appState.signUpWithEmail(email: email, password: pw)
        : await appState.signInWithEmail(email: email, password: pw);
    if (!mounted) return;
    setState(() => _loading = false);

    if (msg == null) {
      Navigator.pop(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.paper,
      appBar: AppBar(title: Text(_signupMode ? '이메일 회원가입' : '이메일 로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '이메일',
                  filled: true,
                  fillColor: AC.paper2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  filled: true,
                  fillColor: AC.paper2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AC.stamp,
                    foregroundColor: AC.paper,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _loading ? '처리 중...' : (_signupMode ? '회원가입' : '로그인'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              TextButton(
                onPressed: _loading ? null : () => setState(() => _signupMode = !_signupMode),
                child: Text(_signupMode ? '이미 계정이 있어요. 로그인' : '계정이 없어요. 회원가입'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        final email = _email.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('비밀번호 재설정 메일을 받을 이메일을 입력해주세요.')),
                          );
                          return;
                        }
                        final msg = await context.read<AppState>().sendPasswordResetEmail(email);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg ?? '비밀번호 재설정 메일을 보냈어요. 메일함을 확인해주세요.'),
                          ),
                        );
                      },
                child: const Text('비밀번호를 잊으셨나요?'),
              ),
              Text(
                'Supabase 이메일 인증이 켜져 있다면 가입 후 메일 인증이 필요할 수 있어요.',
                style: TextStyle(fontSize: 11, color: AC.ink3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══ 닉네임 ════════════════════════════════════════════
class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});
  @override
  State<NicknameScreen> createState() => _NicknameState();
}
class _NicknameState extends State<NicknameScreen> {
  final _c = TextEditingController();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.paper,
    body: SafeArea(child: Column(children: [
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎫', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          const Text('어떻게 불러드릴까요?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AC.ink, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text('철도 마스터에서 사용할\n닉네임을 정해주세요', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AC.ink3, height: 1.6)),
          const SizedBox(height: 32),
          ValueListenableBuilder(valueListenable: _c, builder: (_, val, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(controller: _c, maxLength: 10, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AC.ink),
                decoration: InputDecoration(
                  hintText: '닉네임 입력', hintStyle: const TextStyle(color: AC.ink4),
                  counterText: '', filled: true, fillColor: AC.paper2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AC.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AC.stamp, width: 2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AC.border)),
                )),
              const SizedBox(height: 6),
              Text('${val.text.length} / 10', style: const TextStyle(fontSize: 11, color: AC.ink3)),
            ],
          )),
        ]))),
      Padding(padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
        child: SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final nick = _c.text.trim().isEmpty ? '철도인' : _c.text.trim();
              await context.read<AppState>().saveNickname(nick);
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AC.stamp, foregroundColor: AC.paper,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('다음', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))))),
    ])),
  );
}

// ══ 온보딩 ════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardState();
}
class _OnboardState extends State<OnboardingScreen> {
  int _page = 0;
  final _ctrl = PageController();
  final _pages = const [
    {'emoji':'🐦','title':'역에는 까치가 산다지...','desc':'지하철이 역에 서는 그 순간\n앱을 열면 스탬프가 찍혀요\n내리지 않아도 돼요','bg':AC.stamp,'light':true},
    {'emoji':'🗺️','title':'전국 역을 모두\n철도 마스터가 되어보세요','desc':'역마다 다른 스탬프\n지도를 가득 채워봐요','bg':AC.paper,'light':false},
  ];
  void _goMain() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    final light = p['light'] as bool;
    return Scaffold(
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: _pages.length,
          itemBuilder: (_, i) {
            final pg = _pages[i]; final lt = pg['light'] as bool;
            return Container(color: pg['bg'] as Color, padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(pg['emoji']! as String, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 24),
                Text(pg['title']! as String, textAlign: TextAlign.center, style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.3,
                  color: lt ? AC.paper : AC.ink)),
                const SizedBox(height: 12),
                Text(pg['desc']! as String, textAlign: TextAlign.center, style: TextStyle(
                  fontSize: 15, height: 1.7, color: lt ? AC.paper.withValues(alpha: 0.65) : AC.ink3)),
                const SizedBox(height: 160),
              ]));
          }),
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(color: p['bg'] as Color, padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _page ? 20 : 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                    color: i == _page ? (light ? AC.paper : AC.stamp) : (light ? AC.paper.withValues(alpha: 0.3) : AC.paper3))))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _page < _pages.length - 1
                    ? _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                    : _goMain(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: light ? AC.paper : AC.stamp,
                    foregroundColor: light ? AC.stamp : AC.paper,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: Text(_page < _pages.length - 1 ? '다음' : '시작하기',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)))),
            ]))),
        Positioned(top: 52, right: 18,
          child: GestureDetector(onTap: _goMain,
            child: Text('건너뛰기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: light ? AC.paper.withValues(alpha: 0.4) : AC.ink3)))),
      ]),
    );
  }
}

// ══ 메인 ══════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainState();
}
class _MainState extends State<MainScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tabs = [HomeTab(state: state), CollectionTab(state: state), MapTab(state: state), MeTab(state: state)];
    return Scaffold(
      backgroundColor: AC.paper,
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: _BottomBar(current: _tab, onTap: (i) => setState(() => _tab = i)),
      floatingActionButton: _StampFAB(state: state),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _StampFAB extends StatelessWidget {
  final AppState state;
  const _StampFAB({required this.state});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      if (state.stations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('역 데이터 로딩 중이에요. 잠시 후 다시 시도해주세요.')),
        );
        return;
      }
      final pos = await state.getCurrentPosition();
      if (!context.mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.lastStampError ?? '현재 위치를 확인할 수 없어요.')),
        );
        return;
      }

      final nearest = state.getNearestStationsFromPosition(pos, limit: 5, onlyUnstamped: true);
      if (nearest.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택 가능한 역이 없어요.')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => NearbyStationPickerSheet(
          userPosition: pos,
          candidates: nearest,
          onPick: (picked) async {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => GpsSheet(station: picked.station, onConfirm: () async {
                Navigator.pop(context);
                final ok = await state.stampStation(picked.station);
                if (!context.mounted) return;
                if (ok) {
                  await showDialog(context: context, builder: (_) => StampDialog(station: picked.station));
                  if (!context.mounted) return;
                  final unlocked = state.consumeRecentUnlockedBadges();
                  if (unlocked.isNotEmpty) {
                    await showDialog(
                      context: context,
                      builder: (_) => BadgeUnlockedDialog(badges: unlocked),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.lastStampError ?? '현재 위치가 역 반경 100m 이내일 때만 스탬프를 찍을 수 있어요.',
                      ),
                    ),
                  );
                }
              }),
            );
          },
        ),
      );
    },
    child: Container(width: 58, height: 58,
      decoration: const BoxDecoration(color: AC.stamp, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x401B3A6B), blurRadius: 16, offset: Offset(0, 4))]),
      child: const Icon(Icons.my_location_rounded, color: AC.paper, size: 26)));
}

class NearbyStationPickerSheet extends StatefulWidget {
  /// 스탬프 판정·거리 계산에 사용 (검색 시 전체 미스탬프 역 조회).
  final Position userPosition;
  final List<StationDistance> candidates;
  final ValueChanged<StationDistance> onPick;
  const NearbyStationPickerSheet({
    super.key,
    required this.userPosition,
    required this.candidates,
    required this.onPick,
  });

  @override
  State<NearbyStationPickerSheet> createState() => _NearbyStationPickerSheetState();
}

class _NearbyStationPickerSheetState extends State<NearbyStationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<StationDistance> _nearestFive = [];
  List<StationDistance> _visible = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _nearestFive = List<StationDistance>.from(widget.candidates);
    _visible = _nearestFive;
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final appState = context.read<AppState>();
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _visible = List<StationDistance>.from(_nearestFive));
      return;
    }
    final full = appState.getNearestStationsFromPosition(
      widget.userPosition,
      limit: 800,
      onlyUnstamped: true,
    );
    final filtered = full.where((c) {
      final s = c.station;
      return s.name.toLowerCase().contains(q) ||
          s.en.toLowerCase().contains(q) ||
          s.line.toLowerCase().contains(q);
    }).take(60).toList(growable: false);
    setState(() => _visible = filtered);
  }

  Future<void> _refreshNearby() async {
    setState(() => _isRefreshing = true);
    final appState = context.read<AppState>();
    final pos = await appState.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.lastStampError ?? '현재 위치를 확인할 수 없어요.')),
      );
      return;
    }

    final nearest = appState.getNearestStationsFromPosition(
      pos,
      limit: 5,
      onlyUnstamped: true,
    );
    setState(() {
      _isRefreshing = false;
      _nearestFive = nearest;
      _searchController.clear();
      _visible = nearest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.paper, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('가까운 역 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AC.ink)),
          const SizedBox(height: 4),
          Text(
            '아래는 가까운 미스탬프 역 5곳이에요. 검색하면 전체 미스탬프 역에서 찾아요.',
            style: TextStyle(fontSize: 12, color: AC.ink3, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AC.paper2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AC.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '역 이름 · 노선 검색 (전체 미스탬프)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isRefreshing ? null : _refreshNearby,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, color: AC.stamp),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
            child: _visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('검색 결과가 없어요', style: TextStyle(fontSize: 12, color: AC.ink4)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _visible.map((c) {
            final lc = kLines[c.station.line]?.color ?? AC.ink4;
            final inRange = c.distanceMeters <= 100;
            return InkWell(
              onTap: () => widget.onPick(c),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: inRange ? AC.stampDim : AC.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: inRange ? AC.stamp : AC.border),
                ),
                child: Row(
                  children: [
                    Text(c.station.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.station.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AC.ink)),
                          Text(c.station.line, style: TextStyle(fontSize: 11, color: AC.ink3)),
                        ],
                      ),
                    ),
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: lc, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      inRange
                          ? '${c.distanceMeters.toStringAsFixed(0)}m ✓'
                          : '${c.distanceMeters.toStringAsFixed(0)}m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: inRange ? AC.stamp : AC.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int current;
  final Function(int) onTap;
  const _BottomBar({required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, '홈'),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, '도감'),
      (Icons.circle, Icons.circle, ''),
      (Icons.map_outlined, Icons.map_rounded, '지도'),
      (Icons.person_outline, Icons.person_rounded, '나'),
    ];
    return BottomAppBar(
      color: AC.paper2, elevation: 12, notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(height: 62, child: Row(
        children: List.generate(items.length, (i) {
          if (i == 2) return const Expanded(child: SizedBox());
          final tabIdx = i < 2 ? i : i - 1;
          final on = tabIdx == current;
          return Expanded(child: InkWell(
            onTap: () => onTap(tabIdx),
            splashColor: Colors.transparent,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(on ? items[i].$2 : items[i].$1, color: on ? AC.stamp : AC.ink4, size: 24),
              const SizedBox(height: 2),
              Text(items[i].$3, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: on ? AC.stamp : AC.ink4)),
            ])));
        }))));
  }
}

// ══ GPS 팝업 ══════════════════════════════════════════
class GpsSheet extends StatefulWidget {
  final Station station;
  final VoidCallback onConfirm;
  const GpsSheet({super.key, required this.station, required this.onConfirm});

  @override
  State<GpsSheet> createState() => _GpsSheetState();
}

class _GpsSheetState extends State<GpsSheet> {
  bool _isChecking = true;
  double? _distance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkDistance();
  }

  Future<void> _checkDistance() async {
    final appState = context.read<AppState>();
    setState(() {
      _isChecking = true;
      _error = null;
    });

    final pos = await appState.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _isChecking = false;
        _distance = null;
        _error = appState.lastStampError ?? '현재 위치를 확인할 수 없어요.';
      });
      return;
    }

    final d = distanceMeters(
      lat1: pos.latitude,
      lng1: pos.longitude,
      lat2: widget.station.lat,
      lng2: widget.station.lng,
    );
    setState(() {
      _isChecking = false;
      _distance = d;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final lc = kLines[station.line]?.color ?? AC.stamp;
    final canStamp = !_isChecking && _error == null && (_distance ?? double.infinity) <= 100;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.paper, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _GpsPulse(),
        const SizedBox(height: 20),
        Text('위치 확인됨 ✓', style: TextStyle(fontSize: 11, color: AC.ink3, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(station.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AC.ink, letterSpacing: -1)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: lc, borderRadius: BorderRadius.circular(20)),
          child: Text(station.line, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
        const SizedBox(height: 4),
        if (_isChecking)
          Text('현재 위치 확인 중...', style: TextStyle(fontSize: 12, color: AC.ink4))
        else if (_error != null)
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.redAccent))
        else
          Text(
            '현재 거리 ${(_distance ?? 0).toStringAsFixed(0)}m · 반경 100m 이내에서 인증 가능',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: canStamp ? AC.stamp : Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: canStamp ? widget.onConfirm : null,
            style: ElevatedButton.styleFrom(backgroundColor: AC.stamp, foregroundColor: AC.paper, disabledBackgroundColor: AC.paper3,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: Text(
              canStamp ? '✓  네, 여기 맞아요!' : '반경 100m 내에서만 가능',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ))),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _isChecking ? null : _checkDistance,
              child: Text('거리 다시 확인', style: TextStyle(fontSize: 14, color: AC.stamp)),
            ),
            TextButton(onPressed: () => Navigator.pop(context),
              child: Text('아니요, 다른 역이에요', style: TextStyle(fontSize: 14, color: AC.ink3))),
          ],
        ),
      ]));
  }
}

class _GpsPulse extends StatefulWidget {
  @override
  State<_GpsPulse> createState() => _GpsPulseState();
}
class _GpsPulseState extends State<_GpsPulse> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _a = Tween(begin: 0.7, end: 1.2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, _) => SizedBox(width: 90, height: 90,
      child: Stack(alignment: Alignment.center, children: [
        Transform.scale(scale: _a.value,
          child: Container(width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: AC.stamp.withValues(alpha: 0.06)))),
        Container(width: 60, height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: AC.stamp.withValues(alpha: 0.12),
            border: Border.all(color: AC.stamp.withValues(alpha: 0.3), width: 2)),
          child: const Center(child: Text('📍', style: TextStyle(fontSize: 28)))),
      ])));
}

// ══ 스탬프 획득 다이얼로그 ════════════════════════════
class StampDialog extends StatefulWidget {
  final Station station;
  const StampDialog({super.key, required this.station});
  @override
  State<StampDialog> createState() => _StampDialogState();
}
class _StampDialogState extends State<StampDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  final GlobalKey _shareCardKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _s = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: const ElasticOutCurve(0.8)));
    _c.forward();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Future<void> _shareStampImage() async {
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final xf = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'stamp_${widget.station.id}.png',
      );
      await Share.shareXFiles(
        [xf],
        text: '철도 마스터에서 ${widget.station.name}역 스탬프를 획득했어요! 🚉',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공유에 실패했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lc = kLines[widget.station.line]?.color ?? AC.stamp;
    return Dialog(backgroundColor: Colors.transparent,
      child: ScaleTransition(scale: _s,
        child: Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: AC.paper, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('스탬프 획득!', style: TextStyle(fontSize: 13, color: AC.ink3, letterSpacing: 2)),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: _shareCardKey,
              child: Container(width: 180, height: 180,
                decoration: BoxDecoration(color: AC.stampDim, borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AC.stamp, width: 3)),
                child: Stack(children: [
                  Positioned(top: 0, left: 0, right: 0,
                    child: Container(height: 6,
                      decoration: BoxDecoration(color: lc,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))))),
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(widget.station.icon, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text(widget.station.en.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.stamp)),
                    Text(widget.station.line, style: TextStyle(fontSize: 10, color: AC.ink3)),
                  ])),
                  Positioned(bottom: 10, right: 10,
                    child: Text('CERTIFIED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AC.stamp.withValues(alpha: 0.3), letterSpacing: 2))),
                ])),
            ),
            const SizedBox(height: 16),
            Text(widget.station.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AC.ink, letterSpacing: -1)),
            const SizedBox(height: 4),
            Text('${widget.station.region} · ${widget.station.line}', style: TextStyle(fontSize: 13, color: AC.ink3)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AC.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('홈으로', style: TextStyle(color: AC.ink3, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: _shareStampImage,
                style: ElevatedButton.styleFrom(backgroundColor: AC.stamp, foregroundColor: AC.paper,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('공유하기', style: TextStyle(fontWeight: FontWeight.w900)))),
            ]),
          ]))));
  }
}

class BadgeUnlockedDialog extends StatelessWidget {
  final List<Badge> badges;
  const BadgeUnlockedDialog({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AC.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉 뱃지 획득!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AC.ink)),
            const SizedBox(height: 12),
            ...badges.take(3).map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(b.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AC.ink2)),
                        Text(b.desc, style: const TextStyle(fontSize: 11, color: AC.ink3)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            if (badges.length > 3)
              Text('외 ${badges.length - 3}개 뱃지 추가 획득', style: const TextStyle(fontSize: 12, color: AC.ink3)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AC.stamp, foregroundColor: AC.paper),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══ 홈 탭 ═════════════════════════════════════════════
class HomeTab extends StatefulWidget {
  final AppState state;
  const HomeTab({super.key, required this.state});
  @override
  State<HomeTab> createState() => _HomeTabState();
}
class _HomeTabState extends State<HomeTab> {
  bool _showAll = false;
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final stats = state.lineStats;
    final sorted = stats.keys.toList()
      ..sort((a, b) {
        final pA = stats[a]!['got']! / stats[a]!['total']!;
        final pB = stats[b]!['got']! / stats[b]!['total']!;
        return pB.compareTo(pA);
      });
    final display = _showAll ? sorted : sorted.take(6).toList();

    return SafeArea(child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${state.nickname}님',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AC.ink, letterSpacing: -1)),
          Text('전국 역을 하나씩 모아봐요', style: TextStyle(fontSize: 12, color: AC.ink3)),
        ]))),
      // 통계
      SliverToBoxAdapter(child: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: AC.border))),
        child: Row(children: [
          _Stat('${state.gotCount}', '찍은 역'),
          _Stat('${state.totalStations}', '전체 역'),
          _Stat('${state.completionPct.toStringAsFixed(1)}%', '완성도', last: true),
        ]))),
      // 노선별
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('노선별 현황', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.ink3, letterSpacing: 1)),
          const SizedBox(height: 10),
          ...display.map((line) {
            final info = kLines[line];
            final g = stats[line]!['got']!;
            final t = stats[line]!['total']!;
            return _LineRow(line: line, color: info?.color ?? AC.ink4, got: g, total: t, progress: t > 0 ? g / t : 0);
          }),
          const SizedBox(height: 8),
          Center(child: GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll ? '접기 ↑' : '노선 전체 보기 ↓',
              style: const TextStyle(fontSize: 12, color: AC.stamp, fontWeight: FontWeight.w700)))),
        ]))),
      // 최근 찍은 역
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
        child: Text('최근에 찍은 역', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.ink3, letterSpacing: 1)))),
      SliverToBoxAdapter(child: SizedBox(height: 118,
        child: state.recentStations.isEmpty
          ? Center(child: Text('첫 역을 찍어볼까요? 🚉', style: TextStyle(color: AC.ink4, fontSize: 13)))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: state.recentStations.length + 1,
              itemBuilder: (_, i) => i == state.recentStations.length
                ? _MoreCard()
                : _RecentCard(station: state.recentStations[i])))),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]));
  }
}

class _Stat extends StatelessWidget {
  final String v, l; final bool last;
  const _Stat(this.v, this.l, {this.last = false});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(border: Border(right: last ? BorderSide.none : BorderSide(color: AC.border))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AC.stamp)),
      Text(l, style: const TextStyle(fontSize: 10, color: AC.ink3, letterSpacing: 0.3)),
    ])));
}

class _LineRow extends StatelessWidget {
  final String line; final Color color; final int got, total; final double progress;
  const _LineRow({required this.line, required this.color, required this.got, required this.total, required this.progress});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 13, height: 13, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      SizedBox(width: 68, child: Text(line, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.ink), overflow: TextOverflow.ellipsis)),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(value: progress, backgroundColor: AC.paper3,
          valueColor: AlwaysStoppedAnimation(color), minHeight: 5))),
      const SizedBox(width: 8),
      SizedBox(width: 40, child: Text('$got/$total', textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 11, color: AC.ink3))),
    ]));
}

class _RecentCard extends StatelessWidget {
  final Station station;
  const _RecentCard({required this.station});
  @override
  Widget build(BuildContext context) {
    final lc = kLines[station.line]?.color ?? AC.ink4;
    return Container(width: 90, margin: const EdgeInsets.only(right: 10),
      child: Container(width: 90, height: 90,
        decoration: BoxDecoration(color: AC.stampDim, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AC.stamp, width: 1.5)),
        child: Stack(children: [
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(station.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 2),
            Text(station.name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AC.stamp)),
          ])),
          Positioned(top: 5, right: 5,
            child: Container(width: 14, height: 14, decoration: BoxDecoration(color: lc, shape: BoxShape.circle))),
        ])));
  }
}

class _MoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 90, margin: const EdgeInsets.only(right: 10),
    child: Container(width: 90, height: 90,
      decoration: BoxDecoration(color: AC.paper2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AC.border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('＋', style: TextStyle(fontSize: 22, color: AC.ink3)),
        Text('더 찍기', style: TextStyle(fontSize: 8, color: AC.ink3, fontWeight: FontWeight.w700)),
      ])));
}

// ══ 도감 탭 ═══════════════════════════════════════════
class CollectionTab extends StatefulWidget {
  final AppState state;
  const CollectionTab({super.key, required this.state});
  @override
  State<CollectionTab> createState() => _CollTabState();
}
class _CollTabState extends State<CollectionTab> {
  String _filter = 'all';
  final _sc = TextEditingController();
  Timer? _searchDebounce;
  List<Station> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onSearchChanged);
    _recomputeFiltered();
  }

  @override
  void didUpdateWidget(covariant CollectionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state.stations, widget.state.stations)) {
      _recomputeFiltered();
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), _recomputeFiltered);
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
    _recomputeFiltered();
  }

  void _recomputeFiltered() {
    final q = _sc.text.trim().toLowerCase();
    final stations = widget.state.stations;
    final lineFilter =
        _filter.startsWith('line:') ? _filter.substring('line:'.length) : null;
    final items = stations.where((s) {
      if (q.isNotEmpty) {
        final name = s.name.toLowerCase();
        final en = s.en.toLowerCase();
        final line = s.line.toLowerCase();
        if (!name.contains(q) && !en.contains(q) && !line.contains(q)) return false;
      }
      if (lineFilter != null) return s.line == lineFilter;
      switch (_filter) {
        case 'got':
          return s.got;
        case '수도권':
          return kLines[s.line]?.region == '수도권';
        case 'KTX':
          return ['KTX', 'SRT', 'ITX', '무궁화'].contains(s.line);
        case '부산':
          return kLines[s.line]?.region == '부산';
        case '대구':
          return kLines[s.line]?.region == '대구';
        case '광주':
          return kLines[s.line]?.region == '광주';
        case '대전':
          return kLines[s.line]?.region == '대전';
        default:
          return true;
      }
    }).toList(growable: false);
    if (!mounted) return;
    setState(() => _filteredItems = items);
  }

  /// kLines 정의 순서 우선, 데이터에만 있는 기타 노선은 뒤에 붙임.
  List<String> _orderedLinesPresent() {
    final present = widget.state.stations.map((s) => s.line).toSet();
    final out = <String>[];
    for (final k in kLines.keys) {
      if (present.contains(k)) out.add(k);
    }
    final rest = present.where((p) => !out.contains(p)).toList()..sort();
    out.addAll(rest);
    return out;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _sc.removeListener(_onSearchChanged);
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final got = items.where((s) => s.got).length;
    final prog = items.isEmpty ? 0.0 : got / items.length;
    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Column(children: [
        Row(children: [
          const Text('스탬프 도감', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AC.ink, letterSpacing: -1)),
          const Spacer(),
          Text('$got개 모음', style: TextStyle(fontSize: 12, color: AC.ink3)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AC.paper2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AC.border)),
          child: Row(children: [
            const Icon(Icons.search, size: 16, color: AC.ink3),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _sc,
              decoration: InputDecoration(hintText: '역 이름, 노선 검색', hintStyle: TextStyle(color: AC.ink4, fontSize: 13),
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              style: const TextStyle(fontSize: 13, color: AC.ink))),
            if (_sc.text.isNotEmpty)
              GestureDetector(onTap: () { _sc.clear(); _recomputeFiltered(); },
                child: const Icon(Icons.close, size: 16, color: AC.ink3)),
          ]),
        ),
      ])),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('권역', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AC.ink3, letterSpacing: 0.8)),
        ),
      ),
      SizedBox(height: 38, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _Chip('전체', 'all', _filter, _setFilter),
          _Chip('수도권', '수도권', _filter, _setFilter),
          _Chip('KTX·일반', 'KTX', _filter, _setFilter),
          _Chip('부산', '부산', _filter, _setFilter),
          _Chip('대구', '대구', _filter, _setFilter),
          _Chip('광주', '광주', _filter, _setFilter),
          _Chip('대전', '대전', _filter, _setFilter),
          _Chip('✓ 모은 것', 'got', _filter, _setFilter),
        ])),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('노선', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AC.ink3, letterSpacing: 0.8)),
        ),
      ),
      SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: [
            for (final line in _orderedLinesPresent())
              _Chip(line, 'line:$line', _filter, _setFilter),
          ],
        ),
      ),
      LinearProgressIndicator(value: prog, backgroundColor: AC.paper3, valueColor: const AlwaysStoppedAnimation(AC.stamp), minHeight: 3),
      Expanded(child: items.isEmpty
        ? Center(child: Text('역을 찾을 수 없어요', style: TextStyle(color: AC.ink4, fontSize: 13)))
        : GridView.builder(padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: items.length,
            itemBuilder: (_, i) => _GridItem(station: items[i]))),
    ]));
  }
}

class _Chip extends StatelessWidget {
  final String label, key_, current; final Function(String) onTap;
  const _Chip(this.label, this.key_, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final on = current == key_;
    return GestureDetector(onTap: () => onTap(key_),
      child: Container(margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? AC.stamp : Colors.transparent, width: 2))),
        child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? AC.stamp : AC.ink3)))));
  }
}

class _GridItem extends StatelessWidget {
  final Station station;
  const _GridItem({required this.station});
  @override
  Widget build(BuildContext context) {
    final lc = kLines[station.line]?.color ?? AC.ink4;
    return Opacity(opacity: station.got ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(color: station.got ? AC.stampDim : AC.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: station.got ? AC.stamp : AC.border, width: station.got ? 1.5 : 1)),
        child: Stack(children: [
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(station.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(station.name, textAlign: TextAlign.center, maxLines: 2,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: station.got ? AC.stamp : AC.ink4))),
          ])),
          Positioned(top: 5, right: 5,
            child: Container(width: 9, height: 9, decoration: BoxDecoration(color: lc, shape: BoxShape.circle))),
          if (station.got)
            Positioned(top: -3, left: -3,
              child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: AC.stamp, shape: BoxShape.circle),
                child: const Center(child: Text('✓', style: TextStyle(fontSize: 10, color: AC.paper, fontWeight: FontWeight.w900))))),
        ])));
  }
}

// ══ 지도 탭 (OpenStreetMap 타일 + 역 위치) ═══════════════
class MapTab extends StatelessWidget {
  final AppState state;
  const MapTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final got = state.stations.where((s) => s.got).length;
    final total = state.stations.length;
    final circles = state.stations
        .map(
          (s) => CircleMarker(
            point: LatLng(s.lat, s.lng),
            radius: s.got ? 7.2 : 4.0,
            color: s.got ? const Color(0xDD1B3A6B) : Colors.transparent,
            borderStrokeWidth: s.got ? 2.0 : 1.2,
            borderColor: s.got ? const Color(0xFFF5F0E8) : AC.ink4,
          ),
        )
        .toList(growable: false);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Row(
              children: [
                const Text('지도', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AC.ink, letterSpacing: -1)),
                const Spacer(),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '$got', style: const TextStyle(fontWeight: FontWeight.w700, color: AC.stamp, fontSize: 14)),
                      TextSpan(text: ' / $total', style: TextStyle(color: AC.ink3, fontSize: 12)),
                      TextSpan(text: '  찍음', style: TextStyle(color: AC.ink3, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(36.85, 127.95),
                    initialZoom: 9.2,
                    minZoom: 5,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'io.github.kjh96.yeokjangnim',
                    ),
                    CircleLayer(circles: circles),
                    SimpleAttributionWidget(
                      source: const Text('OpenStreetMap contributors'),
                      onTap: () => openExternalUrl(context, 'https://www.openstreetmap.org/copyright'),
                      alignment: Alignment.bottomRight,
                      backgroundColor: AC.paper.withValues(alpha: 0.92),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AC.border))),
            child: Row(
              children: [
                _Legend(color: AC.stamp, label: '찍은 역'),
                const SizedBox(width: 16),
                _Legend(color: Colors.transparent, label: '미방문', bordered: true, borderColor: AC.ink4),
                const Spacer(),
                Text('채움=찍은 역 · 빈 원=미방문', style: TextStyle(fontSize: 11, color: AC.ink4)),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool bordered;
  final Color borderColor;
  const _Legend({
    required this.color,
    required this.label,
    this.bordered = false,
    this.borderColor = AC.border,
  });
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle,
      border: bordered ? Border.all(color: borderColor) : null)),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 11, color: AC.ink3)),
  ]);
}

// ══ 나 탭 ═════════════════════════════════════════════
class MeTab extends StatelessWidget {
  final AppState state;
  const MeTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final allBadges = [...kBadges['노선 완주']!, ...kBadges['스토리']!];
    return SafeArea(child: SingleChildScrollView(child: Column(children: [
      // 프로필
      Container(padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.border))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
              onTap: () async {
                const icons = ['🧳', '🚉', '🚆', '🚊', '🗺️', '⭐', '✨', '🧡', '💛', '💚', '💙', '❤️'];
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('프로필 아이콘'),
                    content: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final ic in icons)
                            InkWell(
                              onTap: () async {
                                await state.setProfileIcon(ic);
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ic == state.profileIcon ? AC.stampDim : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(ic, style: const TextStyle(fontSize: 22)),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AC.stampDim,
                  border: Border.all(color: AC.stamp, width: 2),
                ),
                child: Center(
                  child: Text(state.profileIcon, style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${state.nickname}님',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AC.ink)),
                const SizedBox(height: 2),
                Text('전국 역을 모으는 중', style: TextStyle(fontSize: 11, color: AC.ink3)),
              ]),
            ),
            OutlinedButton(
              onPressed: () async {
                final ctrl = TextEditingController(text: state.nickname);
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('닉네임 변경'),
                    content: TextField(
                      controller: ctrl,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        hintText: '닉네임',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('취소'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await state.saveNickname(ctrl.text.trim());
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AC.stamp, foregroundColor: AC.paper),
                        child: const Text('저장'),
                      ),
                    ],
                  ),
                );
                ctrl.dispose();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                side: const BorderSide(color: AC.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
              ),
              child: Text('닉네임 변경',
                style: TextStyle(fontSize: 12, color: AC.ink3)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await context.read<AppState>().signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: const BorderSide(color: AC.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('로그아웃', style: TextStyle(fontSize: 12, color: AC.ink3)),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => _confirmDeleteAccount(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('회원 탈퇴', style: TextStyle(fontSize: 11, color: AC.ink4)),
            ),
          ]),
        ])),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => openExternalUrl(context, kTermsUrl),
              child: const Text('이용약관', style: TextStyle(fontSize: 11)),
            ),
            TextButton(
              onPressed: () => openExternalUrl(context, kPrivacyPolicyUrl),
              child: const Text('개인정보처리방침', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
      // 티켓 카드
      Container(margin: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AC.paper2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.border)),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL STAMPS', style: TextStyle(fontSize: 10, color: AC.ink3, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('${state.gotCount}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AC.stamp, letterSpacing: -1)),
              Text('전국 ${state.totalStations}개 역 중', style: TextStyle(fontSize: 11, color: AC.ink3)),
            ]),
            const Spacer(),
            ElevatedButton.icon(onPressed: () => _shareCollectionProgress(context, state),
              icon: const Icon(Icons.share_rounded, size: 13), label: const Text('도감 공유'),
              style: ElevatedButton.styleFrom(backgroundColor: AC.stamp, foregroundColor: AC.paper,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0)),
          ])),
          Divider(height: 1, color: AC.border),
          IntrinsicHeight(child: Row(children: [
            Expanded(child: _TStat('${state.gotCount}', '이번 달')),
            VerticalDivider(width: 1, color: AC.border),
            Expanded(child: _TStat('${state.gotCount}', '총 역')),
          ])),
        ])),
      // 뱃지
      Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20), child: Column(children: [
        Row(children: [
          Text('획득한 뱃지', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.ink3, letterSpacing: 1)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
            child: const Text('전체 보기 →', style: TextStyle(fontSize: 12, color: AC.stamp, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Row(children: allBadges.take(5).map((b) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(children: [
            Container(height: 56,
              decoration: BoxDecoration(color: b.got ? AC.goldDim : AC.paper2, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: b.got ? AC.gold : AC.border, width: 1.5)),
              child: Center(child: Text(b.icon, style: TextStyle(fontSize: 26, color: b.got ? null : const Color(0x80000000))))),
            const SizedBox(height: 4),
            Text(b.name, textAlign: TextAlign.center, maxLines: 2,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: b.got ? AC.ink3 : AC.ink4)),
          ])))).toList()),
      ])),
      // 최근 기록
      Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('최근 기록', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.ink3, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...state.recentStations.map((s) {
          final lc = kLines[s.line]?.color ?? AC.ink4;
          return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AC.paper2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AC.border)),
            child: Row(children: [
              Text(s.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.ink)),
                Text(s.line, style: TextStyle(fontSize: 11, color: AC.ink3)),
              ])),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: lc, shape: BoxShape.circle)),
            ]));
        }),
        if (state.recentStations.isEmpty)
          Center(child: Text('아직 기록이 없어요', style: TextStyle(color: AC.ink4, fontSize: 13))),
      ])),
      const SizedBox(height: 100),
    ])));
  }
}

class _TStat extends StatelessWidget {
  final String v, l; const _TStat(this.v, this.l);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(children: [
      Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AC.ink)),
      Text(l, style: TextStyle(fontSize: 9, color: AC.ink3, letterSpacing: 0.5)),
    ]));
}

// ══ 뱃지 전체 화면 ════════════════════════════════════
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final all = [...kBadges['노선 완주']!, ...kBadges['스토리']!];
    final got = all.where((b) => b.got).length;
    return Scaffold(backgroundColor: AC.paper,
      appBar: AppBar(title: const Text('뱃지 컬렉션'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
          child: Text('$got / ${all.length} 획득', style: TextStyle(fontSize: 12, color: AC.ink3))),
        ...kBadges.entries.map((e) => Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.ink3, letterSpacing: 1)),
            const SizedBox(height: 12),
            GridView.count(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: e.value.map((b) => GestureDetector(
                onTap: b.got ? () => _detail(context, b) : null,
                child: Column(children: [
                  Expanded(child: Container(
                    decoration: BoxDecoration(color: b.got ? AC.goldDim : AC.paper2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: b.got ? AC.gold : AC.border, width: 1.5)),
                    child: Stack(children: [
                      Center(child: Text(b.icon, style: TextStyle(fontSize: 28, color: b.got ? null : const Color(0x40000000)))),
                      if (b.got) Positioned(top: -3, right: -3,
                        child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: AC.gold, shape: BoxShape.circle),
                          child: const Center(child: Text('✓', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900))))),
                    ]))),
                  const SizedBox(height: 5),
                  Text(b.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: b.got ? AC.ink2 : AC.ink4)),
                ]))).toList()),
          ]))),
        const SizedBox(height: 40),
      ])));
  }

  void _detail(BuildContext context, Badge b) => showDialog(context: context,
    builder: (_) => Dialog(backgroundColor: AC.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(b.icon, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(b.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AC.ink)),
        const SizedBox(height: 6),
        Text(b.desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AC.ink3, height: 1.5)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AC.goldDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: AC.gold)),
          child: const Text('획득 완료 ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.gold))),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('닫기', style: TextStyle(color: AC.ink3))),
      ]))));
}
