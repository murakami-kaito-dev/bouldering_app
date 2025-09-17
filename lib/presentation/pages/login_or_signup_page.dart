import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/common/app_logo.dart';
import '../components/common/switcher_tab.dart';
import '../providers/auth_provider.dart';
import 'password_reset_page.dart';

class LoginOrSignUpPage extends ConsumerStatefulWidget {
  const LoginOrSignUpPage({super.key});

  @override
  _LoginOrSignUpPageState createState() => _LoginOrSignUpPageState();
}

class _LoginOrSignUpPageState extends ConsumerState<LoginOrSignUpPage> {
  // パスワードを管理する変数
  String _password = '';
  // メールアドレスを管理する変数
  String _mailAddress = '';
  // メールアドレス確認用の変数（新規登録のみ）
  String _mailAddressConfirm = '';
  // ローディング表示：ログイン・新規登録時の状態表示する変数
  bool _isLoading = false;
  // パスワード可視化状態（ログイン用）
  bool _isLoginPasswordVisible = false;
  // パスワード可視化状態（新規登録用）
  bool _isSignupPasswordVisible = false;

  /// メールアドレス形式チェック
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  // AppBar相当
                  SafeArea(
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // タブバー部分
                  const SwitcherTab(leftTabName: "ログイン", rightTabName: "新規登録"),

                  // タブの内容部分
                  Expanded(
                    child: TabBarView(
                      children: [
                        // ログインタブの中身
                        SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: MediaQuery.of(context).viewInsets.bottom +
                                18, // 下部にキーボード高さ分の余白
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 余白
                              const SizedBox(height: 32),

                              // ロゴ
                              const Center(child: AppLogo()),
                              const SizedBox(height: 24),

                              // メールアドレスの入力欄
                              const Text(
                                'メールアドレス',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // メールアドレス テキストフォーム
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: "boulder@example.com",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _mailAddress = value,
                              ),
                              const SizedBox(height: 24),

                              // パスワードの入力欄
                              const Text(
                                'パスワード',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // パスワードテキストフォーム
                              TextField(
                                obscureText: !_isLoginPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: "8文字以上の半角英数",
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isLoginPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isLoginPasswordVisible = !_isLoginPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (value) => _password = value,
                              ),

                              // パスワードを忘れた方へのリンク
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PasswordResetPage(),
                                            ),
                                          );
                                        },
                                  child: const Text(
                                    'パスワードを忘れた方はこちら',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ログインボタン
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  // UI層でエラーハンドリング・画面遷移を実行
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          // ログイン処理開始
                                          setState(() => _isLoading = true);

                                          try {
                                            await ref
                                                .read(authProvider.notifier)
                                                .login(_mailAddress, _password);

                                            // ログイン成功のメッセージ
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('ログインに成功しました'),
                                                  backgroundColor: Colors.green,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );

                                              // 前の画面に戻る
                                              Navigator.of(context).pop();
                                            }
                                          } catch (e) {
                                            // エラーハンドリング（UI層で実行）
                                            if (mounted) {
                                              String errorMessage =
                                                  'ログインに失敗しました';

                                              // エラータイプに応じてメッセージを調整
                                              if (e
                                                  .toString()
                                                  .contains('user-not-found')) {
                                                errorMessage = 'ユーザーが見つかりません';
                                              } else if (e
                                                  .toString()
                                                  .contains('wrong-password')) {
                                                errorMessage = 'パスワードが違います';
                                              } else if (e
                                                  .toString()
                                                  .contains('invalid-email')) {
                                                errorMessage =
                                                    'メールアドレスの形式が正しくありません';
                                              } else if (e.toString().contains(
                                                  'network-request-failed')) {
                                                errorMessage =
                                                    'ネットワークエラーです。接続を確認してください';
                                              }

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(errorMessage),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(
                                                      seconds: 3),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                  () => _isLoading = false);
                                            }
                                          }
                                        },
                                  child: const Text("ログイン"),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 新規登録タブの中身
                        SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: MediaQuery.of(context).viewInsets.bottom +
                                18, // 下部にキーボード高さ分の余白
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 余白
                              const SizedBox(height: 32),

                              // アイコン
                              const Center(child: AppLogo()),
                              const SizedBox(height: 24),

                              // メールアドレスの入力欄
                              const Text(
                                'メールアドレス',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                decoration: const InputDecoration(
                                  hintText: "boulder@example.com",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _mailAddress = value,
                              ),
                              const SizedBox(height: 16),

                              // メールアドレス確認の入力欄
                              const Text(
                                'メールアドレス（確認）',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                decoration: const InputDecoration(
                                  hintText: "上記と同じメールアドレスを入力",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    _mailAddressConfirm = value,
                              ),
                              const SizedBox(height: 24),

                              // パスワードの入力欄
                              const Text(
                                'パスワード',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                obscureText: !_isSignupPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: "8文字以上の半角英数",
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isSignupPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSignupPasswordVisible = !_isSignupPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (value) => _password = value,
                              ),
                              const SizedBox(height: 8),

                              const Text(
                                'パスワードの条件：\n・8文字以上\n・英大文字・英小文字・数字をそれぞれ1文字以上含めてください',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  // UI層でエラーハンドリング・画面遷移を実行
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          // メールアドレス一致チェック
                                          if (_mailAddress !=
                                              _mailAddressConfirm) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'メールアドレスが一致しません。再度確認してください。'),
                                                backgroundColor: Colors.orange,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                            return;
                                          }

                                          // メールアドレス形式チェック
                                          if (!_isValidEmail(_mailAddress)) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'メールアドレスの形式が正しくありません。'),
                                                backgroundColor: Colors.orange,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                            return;
                                          }

                                          // 新規登録処理開始
                                          setState(() => _isLoading = true);

                                          try {
                                            // サインアップ処理開始(要リファクタリング)
                                            await ref
                                                .read(authProvider.notifier)
                                                .signUp(
                                                    _mailAddress, _password);

                                            // 新規登録成功のメッセージ
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('新規登録が完了しました！'),
                                                  backgroundColor: Colors.green,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );

                                              // マイページへ遷移（ログイン画面を閉じる）
                                              Navigator.of(context).pop();
                                            }
                                          } catch (e) {
                                            // エラーハンドリング（UI層で実行）
                                            if (mounted) {
                                              String errorMessage =
                                                  '新規登録に失敗しました';

                                              // エラータイプに応じてメッセージを調整
                                              if (e.toString().contains(
                                                  'email-already-in-use')) {
                                                errorMessage =
                                                    'そのメールアドレスは既に使用されています';
                                              } else if (e.toString().contains(
                                                      'weak-password') ||
                                                  e.toString().contains(
                                                      'パスワードが指定された条件を満たしていません')) {
                                                errorMessage =
                                                    'パスワードが条件を満たしていません（8文字以上、英大文字・小文字・数字を含む）';
                                              } else if (e
                                                  .toString()
                                                  .contains('invalid-email')) {
                                                errorMessage =
                                                    'メールアドレスの形式が正しくありません';
                                              } else if (e.toString().contains(
                                                  'network-request-failed')) {
                                                errorMessage =
                                                    'ネットワークエラーです。接続を確認してください';
                                              }

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(errorMessage),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(
                                                      seconds: 3),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                  () => _isLoading = false);
                                            }
                                          }
                                        },
                                  child: const Text("新規登録"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ローディング中に表示されるオーバーレイ
              if (_isLoading) ...[
                ModalBarrier(
                    dismissible: false, color: Colors.black.withOpacity(0.3)),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      );
    });
  }
}
