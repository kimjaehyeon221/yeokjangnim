import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'app_state.dart';
import 'open_external_url.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

const kPrivacyPolicyUrl =
    'https://kimjaehyeon221.github.io/yeokjangnim/privacy-policy.html';
const kTermsUrl = 'https://kimjaehyeon221.github.io/yeokjangnim/terms.html';

Future<void> _shareCollectionProgress(
  BuildContext context,
  AppState state,
) async {
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
    return '역 도감에서 전국 역 스탬프 $got / $total개 모았어요! 🚉';
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('복사했어요.')));
  }

  Future<void> _shareImage() async {
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final xf = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'yeokjangnim_stamps.png',
      );
      await Share.shareXFiles([xf], text: _shareText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 공유에 실패했어요: $e')));
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
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331B3A6B),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '역 도감',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AC.stamp,
                        letterSpacing: 3.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.state.nickname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AC.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$got / $total',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AC.stamp,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      '전국 역 스탬프',
                      style: TextStyle(fontSize: 11, color: AC.ink3),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: AC.paper2,
                        color: AC.stamp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              _shareText,
              style: const TextStyle(fontSize: 12, color: AC.ink2, height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _copyText,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AC.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '텍스트 복사',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AC.ink2,
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '이미지 공유',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Supabase.initialize(
    url: 'https://qbfoomdzdssspkvbpdev.supabase.co',
    anonKey: 'sb_publishable_TsNqH8MaqBfqvsg16oACvw_wtvLdIsk',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const YeokjangApp(),
    ),
  );
}

class YeokjangApp extends StatelessWidget {
  const YeokjangApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '역 도감',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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

class _SplashState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
      _initAndRoute();
    });
  }

  Future<void> _initAndRoute() async {
    final state = context.read<AppState>();
    final minSplash = Future.delayed(const Duration(milliseconds: 1500));
    await Future.wait([state.init(), minSplash]);
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      state.userId = session.user.id;
      await state.retryPendingStamps();
      await state.syncProfileFromRemote();
      if (!mounted) return;
      if (state.profileReady) {
        if (state.onboardingSeen) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NicknameScreen()),
        );
      }
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const grad = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0E1016), Color(0xFF131A28), Color(0xFF1B2638)],
      ),
    );
    return Scaffold(
      body: Container(
        decoration: grad,
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 780),
            curve: Curves.easeOutCubic,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  if (_visible)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.94, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: const Center(
                          child: Text('🚉', style: TextStyle(fontSize: 42)),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 96, height: 96),
                  const SizedBox(height: 40),
                  Text(
                    '전국 철도역 스탬프',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.8,
                      color: Colors.white.withValues(alpha: 0.36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '역 도감',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.4,
                      color: Colors.white.withValues(alpha: 0.96),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '멈추지 않아도 괜찮아요.\n지나온 길은 도감에 남거든요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(flex: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (!mounted) return;
      final event = data.event;
      final session = data.session;
      if ((event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.initialSession) &&
          session != null) {
        final state = context.read<AppState>();
        state.userId = session.user.id;
        await state.retryPendingStamps();
        await state.syncProfileFromRemote();
        if (!mounted) return;
        if (state.profileReady) {
          if (state.onboardingSeen) {
            _goMain(context);
          } else {
            _goOnboarding(context);
          }
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

  void _goOnboarding(BuildContext ctx) => Navigator.pushReplacement(
    ctx,
    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
  );

  void _goNickname(BuildContext ctx) => Navigator.pushReplacement(
    ctx,
    MaterialPageRoute(builder: (_) => const NicknameScreen()),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1016), Color(0xFF131A28), Color(0xFF1B2638)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              const Spacer(flex: 4),
              Text(
                '전국 철도역 스탬프',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.8,
                  color: Colors.white.withValues(alpha: 0.36),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Center(
                  child: Text('🚉', style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '역 도감',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -1.2,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '지나친 역마다\n오늘이 한 줄씩 쌓여요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.48),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('이메일로 시작하기'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '계속 진행하면 이용약관 및 개인정보처리방침에\n동의한 것으로 간주돼요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.28),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => openExternalUrl(context, kTermsUrl),
                    child: Text(
                      '서비스 이용약관',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ),
                  Text(
                    '  ·  ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        openExternalUrl(context, kPrivacyPolicyUrl),
                    child: Text(
                      '개인정보처리방침',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});
  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  static const _savedEmailKey = 'saved_login_email';
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signupMode = false;
  bool _loading = false;
  bool _saveEmail = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_savedEmailKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      _email.text = saved;
      setState(() {});
    }
  }

  Future<void> _persistEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_saveEmail && email.isNotEmpty) {
      await prefs.setString(_savedEmailKey, email);
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')));
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
      await _persistEmail(email);
      if (!mounted) return;
      final state = context.read<AppState>();
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        state.userId = session.user.id;
        await state.retryPendingStamps();
        await state.syncProfileFromRemote();
        if (!mounted) return;
        if (state.profileReady) {
          if (state.onboardingSeen) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (_) => false,
            );
          }
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const NicknameScreen()),
            (_) => false,
          );
        }
        return;
      }
      if (!mounted) return;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '이메일',
                  filled: true,
                  fillColor: AC.paper2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _submit(),
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  filled: true,
                  fillColor: AC.paper2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _saveEmail,
                      onChanged: (v) => setState(() => _saveEmail = v ?? true),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _saveEmail = !_saveEmail),
                    child: const Text(
                      '이메일 저장',
                      style: TextStyle(fontSize: 13, color: AC.ink3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                onPressed: _loading
                    ? null
                    : () => setState(() => _signupMode = !_signupMode),
                child: Text(_signupMode ? '이미 계정이 있어요. 로그인' : '계정이 없어요. 회원가입'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        final email = _email.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('비밀번호 재설정 메일을 받을 이메일을 입력해주세요.'),
                            ),
                          );
                          return;
                        }
                        final msg = await context
                            .read<AppState>()
                            .sendPasswordResetEmail(email);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              msg ?? '비밀번호 재설정 메일을 보냈어요. 메일함을 확인해주세요.',
                            ),
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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _maxNickLength = 20;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.paper,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: BackButton(
        color: AC.ink3,
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        },
      ),
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('🎫', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text(
                '어떻게 불러드릴까요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AC.ink,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '역 도감에서 사용할 닉네임을 정해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AC.ink3, height: 1.6),
              ),
              const SizedBox(height: 32),
              ValueListenableBuilder(
                valueListenable: _c,
                builder: (_, val, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _c,
                      maxLength: _maxNickLength,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AC.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: '닉네임 입력',
                        hintStyle: const TextStyle(color: AC.ink4),
                        counterText: '',
                        filled: true,
                        fillColor: AC.paper2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AC.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AC.stamp,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AC.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${val.text.length} / $_maxNickLength',
                      style: const TextStyle(fontSize: 11, color: AC.ink3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nick = _c.text.trim().isEmpty
                        ? '철도인'
                        : _c.text.trim();
                    await context.read<AppState>().saveNickname(nick);
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AC.stamp,
                    foregroundColor: AC.paper,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    ),
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
    {
      'emoji': '🚆',
      'title': '모든 걸 다 이해할 필요가 없거든요.',
      'desc': '여기 왔지만 머물러 있지는 않아요.\n지나가며 기록하는 철도 여정으로 시작해요.',
      'caption': '출처: 제인 버킨(Jane Birkin) 인터뷰 발언',
      'bg': AC.stamp,
      'light': true,
    },
    {
      'emoji': '🧭',
      'title': '우리는 머무르기보다\n지나가며 남깁니다.',
      'desc': '역마다 남는 스탬프와 노선 진행으로\n이동의 순간을 작은 컬렉션으로 만들어요.',
      'caption': '역 도감 온보딩',
      'bg': Color(0xFF183252),
      'light': true,
    },
    {
      'emoji': '🗺️',
      'title': '오늘의 노선을 고르고,\n다음 역으로 가볼까요?',
      'desc': '도감 · 노선도 · 배지까지\n여정을 한 화면에서 단단하게 이어집니다.',
      'caption': '역 도감',
      'bg': AC.paper,
      'light': false,
    },
  ];

  Future<void> _goMain() async {
    await context.read<AppState>().markOnboardingSeen();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    final light = p['light'] as bool;
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) {
              final pg = _pages[i];
              final lt = pg['light'] as bool;
              return Container(
                color: pg['bg'] as Color,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pg['emoji']! as String,
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      pg['title']! as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.3,
                        color: lt ? AC.paper : AC.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pg['desc']! as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: lt ? AC.paper.withValues(alpha: 0.65) : AC.ink3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: lt
                            ? AC.paper.withValues(alpha: 0.12)
                            : AC.paper2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: lt
                              ? AC.paper.withValues(alpha: 0.22)
                              : AC.border,
                        ),
                      ),
                      child: Text(
                        pg['caption']! as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: lt
                              ? AC.paper.withValues(alpha: 0.78)
                              : AC.ink3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 160),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: p['bg'] as Color,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _page ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page
                              ? (light ? AC.paper : AC.stamp)
                              : (light
                                    ? AC.paper.withValues(alpha: 0.3)
                                    : AC.paper3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _page < _pages.length - 1
                          ? _ctrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                          : _goMain(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: light ? AC.paper : AC.stamp,
                        foregroundColor: light ? AC.stamp : AC.paper,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _page < _pages.length - 1 ? '다음' : '시작하기',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 44,
            right: 10,
            child: GestureDetector(
              onTap: _goMain,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '건너뛰기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: light ? AC.paper.withValues(alpha: 0.4) : AC.ink3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
  String? _focusedLine;

  void _openLine(String line) {
    setState(() {
      _focusedLine = line;
      _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final requestedLine = state.consumeRequestedLineFocus();
    if (requestedLine != null && requestedLine != _focusedLine) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openLine(requestedLine);
      });
    }
    final tabs = [
      MapTab(state: state, focusedLine: _focusedLine),
      MeTab(state: state, onOpenLine: _openLine),
    ];
    return Scaffold(
      backgroundColor: AC.paper2,
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: _BottomBar(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
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
  State<NearbyStationPickerSheet> createState() =>
      _NearbyStationPickerSheetState();
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
    final filtered = full
        .where((c) {
          final s = c.station;
          return s.name.toLowerCase().contains(q) ||
              s.en.toLowerCase().contains(q) ||
              s.line.toLowerCase().contains(q);
        })
        .take(60)
        .toList(growable: false);
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
      decoration: BoxDecoration(
        color: AC.paper,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '가까운 역 선택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AC.ink,
            ),
          ),
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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.42,
            ),
            child: _visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '검색 결과가 없어요',
                        style: TextStyle(fontSize: 12, color: AC.ink4),
                      ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: inRange ? AC.stampDim : AC.paper2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: inRange ? AC.stamp : AC.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  c.station.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.station.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AC.ink,
                                        ),
                                      ),
                                      Text(
                                        c.station.line,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AC.ink3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: lc,
                                    shape: BoxShape.circle,
                                  ),
                                ),
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
    return Container(
      decoration: BoxDecoration(
        color: AC.paper.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: AC.border.withValues(alpha: 0.7)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: '노선도',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: '나',
          ),
        ],
      ),
    );
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
    final canStamp =
        !_isChecking && _error == null && (_distance ?? double.infinity) <= 100;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.paper,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GpsPulse(),
          const SizedBox(height: 20),
          if (!_isChecking && _error == null)
            Text(
              '위치 확인됨 ✓',
              style: TextStyle(fontSize: 11, color: AC.ink3, letterSpacing: 2),
            ),
          const SizedBox(height: 8),
          Text(
            station.name,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AC.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: lc,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              station.line,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (_isChecking)
            Text(
              '현재 위치 확인 중...',
              style: TextStyle(fontSize: 12, color: AC.ink4),
            )
          else if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            )
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canStamp ? widget.onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AC.stamp,
                foregroundColor: AC.paper,
                disabledBackgroundColor: AC.paper3,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                canStamp ? '✓  네, 여기 맞아요!' : '반경 100m 내에서만 가능',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _isChecking ? null : _checkDistance,
                child: Text(
                  '거리 다시 확인',
                  style: TextStyle(fontSize: 14, color: AC.stamp),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '아니요, 다른 역이에요',
                  style: TextStyle(fontSize: 14, color: AC.ink3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpsPulse extends StatefulWidget {
  @override
  State<_GpsPulse> createState() => _GpsPulseState();
}

class _GpsPulseState extends State<_GpsPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _a = Tween(
      begin: 0.7,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, _) => SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _a.value,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AC.stamp.withValues(alpha: 0.06),
              ),
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AC.stamp.withValues(alpha: 0.12),
              border: Border.all(
                color: AC.stamp.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text('📍', style: TextStyle(fontSize: 28)),
            ),
          ),
        ],
      ),
    ),
  );
}

// ══ 스탬프 획득 다이얼로그 ════════════════════════════
class StampDialog extends StatefulWidget {
  final Station station;
  const StampDialog({super.key, required this.station});
  @override
  State<StampDialog> createState() => _StampDialogState();
}

class _StampDialogState extends State<StampDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  final GlobalKey _shareCardKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _s = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: const ElasticOutCurve(0.8)));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _shareStampImage() async {
    try {
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
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
      await Share.shareXFiles([
        xf,
      ], text: '역 도감에서 ${widget.station.name}역 스탬프를 획득했어요! 🚉');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공유에 실패했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lc = kLines[widget.station.line]?.color ?? AC.stamp;
    final state = context.read<AppState>();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _s,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AC.paper,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '스탬프 획득!',
                style: TextStyle(
                  fontSize: 13,
                  color: AC.ink3,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _shareCardKey,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AC.stampDim,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AC.stamp, width: 3),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: lc,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.station.icon,
                              style: const TextStyle(fontSize: 64),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.station.en.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AC.stamp,
                              ),
                            ),
                            Text(
                              widget.station.line,
                              style: TextStyle(fontSize: 10, color: AC.ink3),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Text(
                          'CERTIFIED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AC.stamp.withValues(alpha: 0.3),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.station.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AC.ink,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.station.region} · ${widget.station.line}',
                style: TextStyle(fontSize: 13, color: AC.ink3),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        state.requestLineFocus(widget.station.line);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AC.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '노선 보기',
                        style: TextStyle(
                          color: AC.ink3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _shareStampImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AC.stamp,
                        foregroundColor: AC.paper,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '공유하기',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
            const Text(
              '🎉 뱃지 획득!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AC.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...badges
                .take(3)
                .map(
                  (b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(b.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AC.ink2,
                                ),
                              ),
                              Text(
                                b.desc,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AC.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (badges.length > 3)
              Text(
                '외 ${badges.length - 3}개 뱃지 추가 획득',
                style: const TextStyle(fontSize: 12, color: AC.ink3),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AC.stamp,
                foregroundColor: AC.paper,
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══ 노선도 탭 (메인) ══════════════════════════════════
class MapTab extends StatefulWidget {
  final AppState state;
  final String? focusedLine;
  const MapTab({super.key, required this.state, this.focusedLine});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  String _region = '전체';
  String? _selectedLine;
  bool _showAllStations = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<LineProgress> get _visibleLines {
    final source = widget.state.lineProgressList;
    List<LineProgress> filtered;
    if (_region == '전체') {
      filtered = source;
    } else if (_region == '간선철도') {
      filtered = source
          .where((line) => line.type == 'rail')
          .toList(growable: false);
    } else {
      filtered = source
          .where((line) => line.region == _region)
          .toList(growable: false);
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((line) {
            if (line.line.toLowerCase().contains(_searchQuery)) return true;
            return line.stations.any(
              (s) =>
                  s.name.toLowerCase().contains(_searchQuery) ||
                  s.en.toLowerCase().contains(_searchQuery),
            );
          })
          .toList(growable: false);
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void didUpdateWidget(covariant MapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedLine != null &&
        widget.focusedLine != oldWidget.focusedLine) {
      final target = widget.state.lineProgressList
          .where((line) => line.line == widget.focusedLine)
          .firstOrNull;
      if (target != null) {
        final nextRegion = target.type == 'rail' ? '간선철도' : target.region;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _region = nextRegion;
            _selectedLine = target.line;
            _searchCtrl.clear();
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onGpsStamp(BuildContext context) async {
    final state = widget.state;
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
    final nearest = state.getNearestStationsFromPosition(
      pos,
      limit: 5,
      onlyUnstamped: true,
    );
    if (nearest.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주변에 미인증 역이 없어요.')));
      return;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NearbyStationPickerSheet(
        userPosition: pos,
        candidates: nearest,
        onPick: (picked) async {
          Navigator.pop(context);
          if (!context.mounted) return;
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => GpsSheet(
              station: picked.station,
              onConfirm: () async {
                Navigator.pop(context);
                final ok = await state.stampStation(picked.station);
                if (!context.mounted) return;
                if (ok) {
                  HapticFeedback.heavyImpact();
                  state.requestLineFocus(picked.station.line);
                  await showDialog(
                    context: context,
                    builder: (_) => StampDialog(station: picked.station),
                  );
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
                        state.lastStampError ??
                            '역 반경 100m 이내에서만 스탬프를 찍을 수 있어요.',
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final allLines = _visibleLines;
    final selected = _resolveSelectedLine(allLines);
    final featured = state.featuredLines.take(6).toList(growable: false);
    final regions = ['전체', '수도권', '부산', '대구', '광주', '대전', '간선철도'];
    final pct = state.completionPct;
    return RefreshIndicator(
      onRefresh: () async {
        await state.loadStamps();
        await state.loadBadges();
      },
      color: AC.stamp,
      child: CustomScrollView(
        slivers: [
          // 히어로: 컬렉션 메인
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AC.night, AC.night2, AC.night3],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    14,
                    AppSpace.screen,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '프리미엄 철도 컬렉션',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Colors.white70,
                                        letterSpacing: 0.2,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${state.nickname}님의 노선도감',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '오늘도 가까운 역 하나를 수집해 보세요. 진행 중인 노선과 다음 인증 후보를 한 번에 볼 수 있어요.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.train_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SurfaceCard(
                        dark: true,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${state.gotCount} / ${state.totalStations}역',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 32,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${pct.toStringAsFixed(1)}% 완료 · ${state.pendingStampCount > 0 ? '동기화 대기 ${state.pendingStampCount}개' : '동기화 완료'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 132,
                                  child: _PrimaryCTAButton(
                                    label: 'GPS 인증',
                                    icon: Icons.gps_fixed_rounded,
                                    onTap: () => _onGpsStamp(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _HeroStatChip(
                                    value: '${state.completedLineCount}',
                                    label: '완주 노선',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _HeroStatChip(
                                    value: state.currentStreak > 0
                                        ? '${state.currentStreak}일'
                                        : '시작',
                                    label: '연속 기록',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _HeroStatChip(
                                    value: '${featured.length}',
                                    label: '진행 중',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 동기화 대기 알림
          if (state.pendingStampCount > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 16,
                      color: Color(0xFFE65100),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '동기화 대기 중 ${state.pendingStampCount}개',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 검색 + 필터
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                18,
                AppSpace.screen,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: '노선 탐색',
                    subtitle: '검색과 지역 필터로 지금 채울 컬렉션을 고르세요.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: '역이름, 노선명으로 검색',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: const Icon(Icons.close_rounded, size: 18),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: regions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final r = regions[i];
                        final on = _region == r;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _region = r;
                            _selectedLine = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: on ? AC.stamp : AC.paper,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              border: Border.all(
                                color: on ? AC.stamp : AC.border,
                              ),
                            ),
                            child: Text(
                              r,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: on ? Colors.white : AC.ink3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 진행 중인 노선
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                8,
                AppSpace.screen,
                0,
              ),
              child: _SectionHeader(
                title: '진행 중인 노선',
                subtitle: selected == null
                    ? '노선을 선택하면 상세 컬렉션이 열립니다.'
                    : '${selected.line} 컬렉션을 보고 있어요.',
                action: TextButton(
                  onPressed: () => setState(() => _selectedLine = null),
                  child: const Text('초기화'),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 126,
              child: allLines.isEmpty
                  ? const _EmptyPanel(message: '조건에 맞는 노선이 없어요.')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.screen,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: allLines.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final line = allLines[index];
                        final isSelected = selected?.line == line.line;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedLine = line.line),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 190,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? line.color.withValues(alpha: 0.12)
                                  : AC.paper,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(
                                color: isSelected ? line.color : AC.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: line.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : AppShadows.card,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: line.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        line.line,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? AC.ink : AC.ink2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  line.type == 'rail'
                                      ? '간선철도 컬렉션'
                                      : '${line.region} 도시철도',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: AC.ink4),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${line.visited}/${line.total}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AC.ink3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${(line.ratio * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: line.color,
                                      ),
                                    ),
                                  ],
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: line.ratio,
                                    minHeight: 4,
                                    backgroundColor: AC.border,
                                    valueColor: AlwaysStoppedAnimation(
                                      line.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          // 선택한 노선 상세
          if (selected != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  20,
                  AppSpace.screen,
                  0,
                ),
                child: _LineDetailCard(
                  progress: selected,
                  showAllStations: _showAllStations,
                  onToggleAllStations: () =>
                      setState(() => _showAllStations = !_showAllStations),
                ),
              ),
            ),
          if (selected == null && allLines.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: _EmptyPanel(message: '노선을 선택해주세요.'),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  LineProgress? _resolveSelectedLine(List<LineProgress> visibleLines) {
    if (visibleLines.isEmpty) return null;
    if (_selectedLine == null) return visibleLines.first;
    return visibleLines
            .where((line) => line.line == _selectedLine)
            .firstOrNull ??
        visibleLines.first;
  }
}

// ══ 나 탭 ═════════════════════════════════════════════
class MeTab extends StatelessWidget {
  final AppState state;
  final ValueChanged<String> onOpenLine;
  const MeTab({super.key, required this.state, required this.onOpenLine});

  @override
  Widget build(BuildContext context) {
    final allBadges = [...(kBadges['노선 완주'] ?? []), ...(kBadges['스토리'] ?? [])];
    final earnedBadges = allBadges
        .where((badge) => badge.got)
        .toList(growable: false);
    final completedLines = state.completedLines;
    final featuredBadges = (earnedBadges.isNotEmpty ? earnedBadges : allBadges)
        .take(6)
        .toList(growable: false);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AC.night, AC.night2],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Lounge',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '프로필 라운지',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    _ProfileOverviewCard(state: state),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _MeStatChip(
                          icon: Icons.approval_rounded,
                          value: '${state.gotCount}',
                          label: '스탬프',
                        ),
                        const SizedBox(width: 10),
                        _MeStatChip(
                          icon: Icons.emoji_events_rounded,
                          value: '${earnedBadges.length}',
                          label: '배지',
                        ),
                        const SizedBox(width: 10),
                        _MeStatChip(
                          icon: Icons.check_circle_rounded,
                          value: '${completedLines.length}',
                          label: '완주',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              24,
              AppSpace.screen,
              0,
            ),
            child: _SurfaceCard(
              dark: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: '대표 배지',
                    subtitle: earnedBadges.isNotEmpty
                        ? '최근 획득하거나 대표로 보여줄 배지예요.'
                        : '아직 배지가 없어요. 첫 인증을 시작해 보세요.',
                    action: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BadgesScreen()),
                      ),
                      child: const Text('전체 보기'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (featuredBadges.isEmpty)
                    const _EmptyPanel(message: '배지가 아직 없어요.')
                  else
                    SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredBadges.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, index) => SizedBox(
                          width: 96,
                          child: _BadgePreviewCard(
                            badge: featuredBadges[index],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              24,
              AppSpace.screen,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: '완주 쇼케이스',
                  subtitle: '완주한 노선은 이곳에서 컬렉션처럼 정리됩니다.',
                ),
                const SizedBox(height: 12),
                if (completedLines.isEmpty)
                  const _EmptyPanel(message: '아직 완주한 노선이 없어요.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: completedLines
                        .map(
                          (line) => _LineStatusPill(
                            progress: line,
                            compact: false,
                            onTap: () => onOpenLine(line.line),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              24,
              AppSpace.screen,
              0,
            ),
            child: _SurfaceCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: '앱 설정',
                    subtitle: '공유, 온보딩, 계정 관리를 여기서 할 수 있어요.',
                  ),
                  const SizedBox(height: 8),
                  _MeAction(
                    icon: Icons.share_rounded,
                    label: '진행 현황 공유',
                    onTap: () => _shareCollectionProgress(context, state),
                  ),
                  _MeDivider(),
                  _MeAction(
                    icon: Icons.play_circle_outline_rounded,
                    label: '온보딩 다시 보기',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    ),
                  ),
                  _MeDivider(),
                  _MeAction(
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    onTap: () async {
                      await context.read<AppState>().signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                  ),
                  _MeDivider(),
                  _MeAction(
                    icon: Icons.delete_outline_rounded,
                    label: '회원 탈퇴',
                    color: AC.danger,
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              '"모든 걸 다 이해할 필요가 없거든요.\n여기 왔지만 머물러 있지는 않아요."\n— 제인 버킨(Jane Birkin)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AC.ink4,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _MeStatChip extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _MeStatChip({
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.white60),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AC.ink3),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? AC.ink2,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AC.ink4),
          ],
        ),
      ),
    );
  }
}

class _MeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 52, color: AC.border);
}

// --- Old MeTab body removed, replaced above ---

class _LineDetailCard extends StatelessWidget {
  final LineProgress progress;
  final bool showAllStations;
  final VoidCallback onToggleAllStations;
  const _LineDetailCard({
    required this.progress,
    required this.showAllStations,
    required this.onToggleAllStations,
  });

  @override
  Widget build(BuildContext context) {
    final nextTargets = progress.stations
        .where((station) => !station.got)
        .take(3)
        .toList(growable: false);
    final visibleStations = showAllStations
        ? progress.stations
        : progress.stations
              .take(progress.type == 'rail' ? 8 : 12)
              .toList(growable: false);
    return _SurfaceCard(
      padding: const EdgeInsets.all(20),
      accent: progress.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.line,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AC.ink,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.region} · ${progress.type == 'rail' ? '간선철도' : '도시철도'}',
                      style: TextStyle(fontSize: 12, color: AC.ink3),
                    ),
                  ],
                ),
              ),
              _InlinePill(
                label: '${progress.visited}/${progress.total}',
                tone: progress.color.withValues(alpha: 0.14),
                textColor: progress.color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.ratio,
              minHeight: 10,
              backgroundColor: AC.paper3,
              valueColor: AlwaysStoppedAnimation(progress.color),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InlinePill(
                label: progress.type == 'rail' ? '간선철도 아카이브' : '도시철도 컬렉션',
                tone: progress.color.withValues(alpha: 0.14),
                textColor: progress.color,
              ),
              _InlinePill(
                label: '남은 역 ${progress.total - progress.visited}',
                tone: AC.paper2,
                textColor: AC.ink3,
              ),
            ],
          ),
          if (nextTargets.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionHeader(
              title: '다음 인증 추천',
              subtitle: '지금 바로 찍기 좋은 역 3곳을 먼저 보여드려요.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nextTargets
                  .map(
                    (station) => _NextTargetChip(
                      station: station,
                      color: progress.color,
                      onTap: () => _showStationDetailSheet(
                        context,
                        station,
                        progress.color,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          const _SectionHeader(
            title: '노선 흐름',
            subtitle: '탭해서 역 상태와 인증 정보를 확인할 수 있어요.',
          ),
          const SizedBox(height: 12),
          if (progress.type == 'rail')
            _RailStationStrip(progress: progress)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var index = 0;
                    index < progress.stations.length;
                    index++
                  ) ...[
                    _StationNode(
                      station: progress.stations[index],
                      color: progress.color,
                      onTap: () => _showStationDetailSheet(
                        context,
                        progress.stations[index],
                        progress.color,
                      ),
                    ),
                    if (index != progress.stations.length - 1)
                      Container(
                        width: 42,
                        height: 2,
                        margin: const EdgeInsets.only(top: 19),
                        color:
                            progress.stations[index].got &&
                                progress.stations[index + 1].got
                            ? progress.color
                            : AC.paper3,
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  '전체 역 컬렉션',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onToggleAllStations,
                child: Text(showAllStations ? '접기' : '더 보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleStations
                .map(
                  (station) => _StationSummaryChip(
                    station: station,
                    color: progress.color,
                    onTap: () => _showStationDetailSheet(
                      context,
                      station,
                      progress.color,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StationNode extends StatelessWidget {
  final Station station;
  final Color color;
  final VoidCallback onTap;
  const _StationNode({
    required this.station,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visited = station.got;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: visited ? color : AC.paper,
                border: Border.all(color: visited ? color : AC.ink4, width: 2),
                boxShadow: visited
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: visited
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : Text(station.icon, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              station.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: visited ? AC.ink : AC.ink3,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationSummaryChip extends StatelessWidget {
  final Station station;
  final Color color;
  final VoidCallback onTap;
  const _StationSummaryChip({
    required this.station,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: station.got ? color.withValues(alpha: 0.12) : AC.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: station.got ? color.withValues(alpha: 0.35) : AC.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(station.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              station.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: station.got ? AC.ink : AC.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailStationStrip extends StatelessWidget {
  final LineProgress progress;
  const _RailStationStrip({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < progress.stations.length; index++) ...[
            _RailStopCard(
              station: progress.stations[index],
              color: progress.color,
              onTap: () => _showStationDetailSheet(
                context,
                progress.stations[index],
                progress.color,
              ),
            ),
            if (index != progress.stations.length - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 22, 8, 0),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: progress.color.withValues(alpha: 0.55),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RailStopCard extends StatelessWidget {
  final Station station;
  final Color color;
  final VoidCallback onTap;
  const _RailStopCard({
    required this.station,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: station.got ? color.withValues(alpha: 0.12) : AC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: station.got ? color.withValues(alpha: 0.4) : AC.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(station.icon, style: const TextStyle(fontSize: 18)),
                const Spacer(),
                Icon(
                  station.got
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: station.got ? color : AC.ink4,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              station.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AC.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              station.region,
              style: TextStyle(fontSize: 11, color: AC.ink4),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showStationDetailSheet(
  BuildContext context,
  Station station,
  Color color,
) async {
  final state = context.read<AppState>();
  final stampedAt = state.stampDates[station.id];
  final lineProgress = state.lineProgressList
      .where((line) => line.line == station.line)
      .firstOrNull;
  final remaining = lineProgress == null
      ? 0
      : lineProgress.total - lineProgress.visited;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AC.paper,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AC.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: station.got
                        ? color.withValues(alpha: 0.15)
                        : AC.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: station.got
                          ? color.withValues(alpha: 0.3)
                          : AC.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      station.icon,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AC.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              station.line,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            station.en.isNotEmpty ? station.en : station.region,
                            style: TextStyle(fontSize: 12, color: AC.ink4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (station.got)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓ 인증',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // 인증 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: station.got ? color.withValues(alpha: 0.05) : AC.paper2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: station.got
                      ? color.withValues(alpha: 0.15)
                      : AC.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        station.got
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: station.got ? color : AC.ink4,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        station.got
                            ? stampedAt != null
                                  ? '${stampedAt.year}.${stampedAt.month.toString().padLeft(2, '0')}.${stampedAt.day.toString().padLeft(2, '0')} ${stampedAt.hour.toString().padLeft(2, '0')}:${stampedAt.minute.toString().padLeft(2, '0')} 인증'
                                  : '인증 완료'
                            : '미인증 — 현장에서 GPS 스탬프를 찍어주세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: station.got ? AC.ink2 : AC.ink3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (lineProgress != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '노선 진행 ',
                          style: TextStyle(fontSize: 11, color: AC.ink4),
                        ),
                        Text(
                          '${lineProgress.visited}/${lineProgress.total}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AC.ink2,
                          ),
                        ),
                        Text(
                          '  ·  남은 역 $remaining',
                          style: TextStyle(fontSize: 11, color: AC.ink4),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // 스탬프 찍기 버튼 (미방문 역만)
            if (!station.got) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    if (!context.mounted) return;
                    await showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => GpsSheet(
                        station: station,
                        onConfirm: () async {
                          Navigator.pop(context);
                          final success = await state.stampStation(station);
                          if (!context.mounted) return;
                          if (success) {
                            HapticFeedback.heavyImpact();
                            state.requestLineFocus(station.line);
                            await showDialog<void>(
                              context: context,
                              builder: (_) => StampDialog(station: station),
                            );
                            if (!context.mounted) return;
                            final unlocked = state
                                .consumeRecentUnlockedBadges();
                            if (unlocked.isNotEmpty) {
                              await showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    BadgeUnlockedDialog(badges: unlocked),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  state.lastStampError ??
                                      '스탬프를 찍을 수 없어요. 역 반경 100m 이내인지 확인해주세요.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: const Text(
                    '여기서 스탬프 찍기',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ProfileOverviewCard extends StatelessWidget {
  final AppState state;
  const _ProfileOverviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            const icons = [
              '🧳',
              '🚉',
              '🚆',
              '🚊',
              '🗺️',
              '⭐',
              '✨',
              '🧡',
              '💛',
              '💚',
              '💙',
              '❤️',
            ];
            await showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => _PremiumBottomSheet(
                title: '프로필 아이콘',
                subtitle: '내 철도 여정을 대표할 아이콘을 골라보세요.',
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
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: ic == state.profileIcon
                                ? AC.stamp.withValues(alpha: 0.12)
                                : AC.paper2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ic == state.profileIcon
                                  ? AC.stamp
                                  : AC.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              ic,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Center(
              child: Text(
                state.profileIcon,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.nickname,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '전국 역을 모으는 중',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () async {
            final ctrl = TextEditingController(text: state.nickname);
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: _PremiumBottomSheet(
                  title: '닉네임 변경',
                  subtitle: '프로필 라운지와 컬렉션 화면에 표시됩니다.',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: ctrl,
                        maxLength: 20,
                        decoration: const InputDecoration(hintText: '닉네임'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await state.saveNickname(ctrl.text.trim());
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                              },
                              child: const Text('저장'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            ctrl.dispose();
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '편집',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _BadgePreviewCard extends StatelessWidget {
  final Badge badge;
  const _BadgePreviewCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: badge.got ? AC.goldDim : AC.paper2,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: badge.got ? AC.gold : AC.border,
                width: 1.2,
              ),
              boxShadow: badge.got ? AppShadows.card : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: 28,
                      color: badge.got ? null : const Color(0x55000000),
                    ),
                  ),
                  if (badge.got) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AC.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: const Text(
                        '획득',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AC.gold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: badge.got ? AC.ink2 : AC.ink4,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _InlinePill extends StatelessWidget {
  final String label;
  final Color tone;
  final Color? textColor;
  const _InlinePill({required this.label, required this.tone, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor ?? AC.paper,
        ),
      ),
    );
  }
}

class _LineStatusPill extends StatelessWidget {
  final LineProgress progress;
  final bool compact;
  final VoidCallback? onTap;
  const _LineStatusPill({
    required this.progress,
    this.compact = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = progress.isComplete
        ? '완주'
        : '${(progress.ratio * 100).round()}%';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: progress.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${progress.line} $label',
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w800,
            color: progress.color,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const _SectionHeader({required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _PrimaryCTAButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryCTAButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AC.stamp,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final bool dark;
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AC.surfaceDark : AC.paper;
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.08)
        : accent?.withValues(alpha: 0.25) ?? AC.border;
    final shadow = dark ? AppShadows.darkCard : AppShadows.card;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: Stack(
        children: [
          if (accent != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadii.xl),
                    topRight: Radius.circular(AppRadii.xl),
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextTargetChip extends StatelessWidget {
  final Station station;
  final Color color;
  final VoidCallback onTap;
  const _NextTargetChip({
    required this.station,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(station.icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AC.ink,
                  ),
                ),
                Text(
                  station.region,
                  style: TextStyle(fontSize: 10, color: AC.ink4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _PremiumBottomSheet({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
      decoration: BoxDecoration(
        color: AC.paper,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AC.border,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;
  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AC.paper,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AC.border),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AC.ink3),
      ),
    );
  }
}

// ══ 뱃지 전체 화면 ════════════════════════════════════
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final all = [...(kBadges['노선 완주'] ?? []), ...(kBadges['스토리'] ?? [])];
    final got = all.where((b) => b.got).length;
    return Scaffold(
      backgroundColor: AC.paper,
      appBar: AppBar(
        title: const Text('뱃지 컬렉션'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: Text(
                '$got / ${all.length} 획득',
                style: TextStyle(fontSize: 12, color: AC.ink3),
              ),
            ),
            ...kBadges.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AC.ink3,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: e.value
                          .map(
                            (b) => GestureDetector(
                              onTap: b.got ? () => _detail(context, b) : null,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: b.got ? AC.goldDim : AC.paper2,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: b.got ? AC.gold : AC.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Text(
                                              b.icon,
                                              style: TextStyle(
                                                fontSize: 28,
                                                color: b.got
                                                    ? null
                                                    : const Color(0x40000000),
                                              ),
                                            ),
                                          ),
                                          if (b.got)
                                            Positioned(
                                              top: -3,
                                              right: -3,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: const BoxDecoration(
                                                  color: AC.gold,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    '✓',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    b.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: b.got ? AC.ink2 : AC.ink4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _detail(BuildContext context, Badge b) => showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AC.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(b.icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              b.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AC.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              b.desc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AC.ink3, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AC.goldDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AC.gold),
              ),
              child: const Text(
                '획득 완료 ✓',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AC.gold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('닫기', style: TextStyle(color: AC.ink3)),
            ),
          ],
        ),
      ),
    ),
  );
}
