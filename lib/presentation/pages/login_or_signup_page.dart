import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/auth_service.dart';
import '../components/common/app_logo.dart';
import '../providers/auth_provider.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

/// ログイン画面（Google / Apple）
///
/// 役割:
/// - Google または Apple でサインインする
/// - 初回サインインがそのまま新規登録になる（ログイン／新規登録の区別は無い）
///
/// 本人確認は各プロバイダが行い、Firebase がその証明を検証してアカウント（uid）を発行する。
/// メールアドレスは認証に使わない（登録後、設定画面から任意で登録できる）
class LoginOrSignUpPage extends ConsumerStatefulWidget {
  const LoginOrSignUpPage({super.key});

  @override
  ConsumerState<LoginOrSignUpPage> createState() => _LoginOrSignUpPageState();
}

class _LoginOrSignUpPageState extends ConsumerState<LoginOrSignUpPage> {
  /// 処理中のプロバイダ（ボタンの二重押し防止・表示用）
  AuthProviderKind? _inProgress;

  Future<void> _signIn(AuthProviderKind kind) async {
    if (_inProgress != null) return;
    setState(() => _inProgress = kind);
    try {
      final ok = await ref.read(authProvider.notifier).signInWith(kind);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      }
      // キャンセル時は何もしない（画面に留まる）
    } catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('ログインに失敗しました', style: AppText.heading(size: 16)),
          content: Text(_friendlyMessage(e), style: AppText.body(size: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _inProgress = null);
    }
  }

  String _friendlyMessage(Object e) {
    final s = e.toString();
    if (s.contains('network')) {
      return AuthNotifier.networkRequestFailedMessage;
    }
    if (s.contains('認証が必要') || s.contains('401')) {
      return 'ログインの確認に失敗しました。時間をおいて再度お試しください。';
    }
    return AuthNotifier.otherErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _inProgress != null;
    return Scaffold(
      backgroundColor: AppColors.iwa,
      body: SafeArea(
        child: Stack(
          children: [
            // 閉じる
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.chalk),
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(),
                    const SizedBox(height: 12),
                    Text(
                      'ログイン / 新規登録',
                      style: AppText.caption(size: 13),
                    ),
                    const SizedBox(height: 32),

                    // Apple（Apple の規約: 他社ログインを出すなら同じ場所に同等以上の扱いで置く）
                    _ProviderButton(
                      label: 'Apple でサインイン',
                      icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                      background: Colors.black,
                      foreground: Colors.white,
                      border: AppColors.wareme,
                      busy: _inProgress == AuthProviderKind.apple,
                      enabled: !busy,
                      onPressed: () => _signIn(AuthProviderKind.apple),
                    ),
                    const SizedBox(height: 12),

                    // Google
                    _ProviderButton(
                      label: 'Google でログイン',
                      icon: const _GoogleMark(),
                      background: Colors.white,
                      foreground: const Color(0xFF1F1F1F),
                      border: Colors.white,
                      busy: _inProgress == AuthProviderKind.google,
                      enabled: !busy,
                      onPressed: () => _signIn(AuthProviderKind.google),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '初めての方も、ボタンを押すだけで登録が完了します。\n'
                      'メールアドレスやパスワードの入力は不要です。',
                      textAlign: TextAlign.center,
                      style: AppText.caption(size: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// プロバイダのログインボタン（幅いっぱいのピル）
class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final Color background;
  final Color foreground;
  final Color border;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withOpacity(0.6),
          disabledForegroundColor: foreground.withOpacity(0.6),
          elevation: 0,
          shape: StadiumBorder(side: BorderSide(color: border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: busy
                  ? CircularProgressIndicator(strokeWidth: 2, color: foreground)
                  : icon,
            ),
            const SizedBox(width: 12),
            Text(label, style: AppText.label(size: 15, color: foreground)),
          ],
        ),
      ),
    );
  }
}

/// Google の「G」マーク（ブランド4色。公式アセットを同梱するまでの簡易描画）
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleMarkPainter());
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final stroke = size.width * 0.2;
    final arcRect = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // 4色の弧（右上→右下→左下→左上）
    const colors = [
      Color(0xFFEA4335), // 赤
      Color(0xFFFBBC05), // 黄
      Color(0xFF34A853), // 緑
      Color(0xFF4285F4), // 青
    ];
    const starts = [-0.75, 0.25, 0.75, -1.25]; // 単位: π ラジアン（時計回り）
    const sweeps = [0.5, 0.5, 0.5, 0.35];
    const pi = 3.141592653589793;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(arcRect, starts[i] * pi, sweeps[i] * pi, false, paint..color = colors[i]);
    }
    // 青の横棒（G の右側）
    final bar = Paint()..color = colors[3];
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.42, size.width * 0.5 - stroke / 2, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
