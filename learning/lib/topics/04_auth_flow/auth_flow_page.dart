import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// トピック04: 認証フローとトークン管理
///
/// 本体の対応箇所:
///   lib/infrastructure/services/firebase_auth_service.dart（Firebase Auth）
///   lib/infrastructure/services/api_client.dart（IDトークンの自動付与）
///   lib/presentation/pages/app.dart（アプリ復帰時の失効チェック）
///
/// 本体の仕組み（このミニアプリで再現するもの）:
///   1. ログインすると認証サービスが「IDトークン」を持つ
///   2. ApiClient が毎リクエストで Authorization: Bearer <token> を自動付与
///   3. トークンには有効期限がある（Firebaseは1時間。ここでは15秒に短縮）
///   4. 期限切れトークンでAPIを叩くと 401 → 検知してログアウトさせる
///
/// FirebaseのSDKは使わず Fake で再現している。
/// 本物との差分は README 参照（本物はSDKが自動リフレッシュする）。
/// ============================================================

/// ---- Fakeの認証サービス（FirebaseAuth の代役）----
class FakeAuthService {
  String? _token;
  DateTime? _expiresAt;

  static const tokenLifetime = Duration(seconds: 15); // 本物は1時間

  bool get isLoggedIn => _token != null;
  DateTime? get expiresAt => _expiresAt;

  Future<void> signIn(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _token = 'fake-id-token-${DateTime.now().millisecondsSinceEpoch}';
    _expiresAt = DateTime.now().add(tokenLifetime);
  }

  void signOut() {
    _token = null;
    _expiresAt = null;
  }

  /// 本体の getIdToken() 相当。期限切れならnullを返す
  /// （本物のFirebaseはここで自動リフレッシュする。それが効かない
  ///   ケース＝パスワード変更・アカウント無効化が「失効」）
  String? getIdToken() {
    if (_expiresAt == null || DateTime.now().isAfter(_expiresAt!)) return null;
    return _token;
  }
}

/// ---- ApiClient: トークン自動付与 + 401ハンドリング ----
/// 本体の対応箇所: api_client.dart:42-90
class FakeApiClient {
  FakeApiClient(this._auth);
  final FakeAuthService _auth;

  /// 戻り値: (statusCode, body)
  Future<(int, String)> get(String path) async {
    // 要点2: 呼び出し側は認証を意識しない。ここで毎回トークンを付ける
    final token = _auth.getIdToken();
    await Future.delayed(const Duration(milliseconds: 300));

    if (token == null) {
      // 要点4: 期限切れ = 401。statusCodeを潰さずに上へ返すのが重要
      // （本体では例外の二重ラップでstatusCodeが失われるバグ候補があった）
      return (401, 'Unauthorized: token expired');
    }
    return (200, '{"path": "$path", "user_tweets": 12}');
  }
}

/// ---- 状態管理 ----
class AuthState {
  const AuthState({this.isLoggedIn = false, this.log = const []});
  final bool isLoggedIn;
  final List<String> log;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _auth = FakeAuthService();
  late final _api = FakeApiClient(_auth);

  Duration? get remaining => _auth.expiresAt?.difference(DateTime.now());

  Future<void> signIn() async {
    await _auth.signIn('climber@example.com');
    _appendLog('ログイン成功。トークン発行（有効期限15秒）');
    state = AuthState(isLoggedIn: true, log: state.log);
  }

  void signOut(String reason) {
    _auth.signOut();
    _appendLog('ログアウト（$reason）');
    state = AuthState(isLoggedIn: false, log: state.log);
  }

  /// APIを叩く。401なら強制ログアウト（本体のトークン失効検知と同じ流れ）
  Future<void> callApi() async {
    final (status, body) = await _api.get('/api/users/me/tweets');
    _appendLog('GET /api/users/me/tweets → $status');
    if (status == 401) {
      signOut('401検知: トークン失効');
    } else {
      _appendLog('  レスポンス: $body');
      state = AuthState(isLoggedIn: true, log: state.log);
    }
  }

  void _appendLog(String message) {
    final t = DateTime.now().toIso8601String().substring(11, 19);
    state = AuthState(
      isLoggedIn: state.isLoggedIn,
      log: [...state.log, '[$t] $message'],
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider.autoDispose<AuthNotifier, AuthState>(
        (ref) => AuthNotifier());

/// ---- 画面 ----
class AuthFlowPage extends ConsumerStatefulWidget {
  const AuthFlowPage({super.key});

  @override
  ConsumerState<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends ConsumerState<AuthFlowPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 残り時間表示を1秒ごとに更新するだけのタイマー（認証ロジックとは無関係）
    _ticker = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);
    final remaining = notifier.remaining;

    return Scaffold(
      appBar: AppBar(title: const Text('04 認証フロー')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isLoggedIn
                      ? 'ログイン中'
                          '（トークン残り ${remaining!.isNegative ? 0 : remaining.inSeconds} 秒）'
                      : '未ログイン',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  '手順: ①ログイン → ②すぐAPI呼び出し(200) → '
                  '③15秒待ってAPI呼び出し(401→強制ログアウト)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: state.isLoggedIn ? null : notifier.signIn,
                      child: const Text('①ログイン'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed:
                          state.isLoggedIn ? notifier.callApi : null,
                      child: const Text('②③API呼び出し'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: state.isLoggedIn
                          ? () => notifier.signOut('手動')
                          : null,
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: Colors.black87,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  state.log.isEmpty ? '（ここに通信ログが出る）' : state.log.join('\n'),
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'Menlo',
                      fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
