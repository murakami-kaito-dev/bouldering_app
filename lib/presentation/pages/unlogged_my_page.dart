import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/user/user_avatar.dart';
import '../components/common/app_logo.dart';
import 'login_or_signup_page.dart';

/// 未ログイン時のマイページ
/// 
/// 役割:
/// - 未ログイン状態でのマイページ表示
/// - アプリの機能紹介
/// - ログイン/新規登録への誘導
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のView
/// - 認証状態に依存しない静的なUI
class UnloggedMyPage extends ConsumerWidget {
  const UnloggedMyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ゲストユーザー表示
              const UserAvatar(
                userName: 'ゲストボルダー',
                isGuest: true,
              ),
              const SizedBox(height: 24),

              // 機能説明コンテナ
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // アプリロゴ
                    const Center(child: AppLogo()),
                    const SizedBox(height: 16),

                    // 説明テキスト
                    const Text(
                      'イワノボリタイに登録すると，ボル活がさらに充実します！登録は無料！',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.50,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 機能説明リスト
                    _buildFeatureSection(
                      '1. 行きたいジムを保存',
                      '気になるジムをお気に入り登録して，行きたいジムリストを作ることができます．',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildFeatureSection(
                      '2. ボル活を記録',
                      'ジムで登った記録や感想を残すことができます．',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildFeatureSection(
                      '3. コンペ（今後追加予定）',
                      'ジムのコンペやイベント，セッションの情報を確認できます．気になるジムをのぞいてみよう！',
                    ),
                    const SizedBox(height: 40),

                    // ログイン/新規登録ボタン
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginOrSignUpPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: 49,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF0056FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '新規登録 / ログイン',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              letterSpacing: -0.50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 機能説明セクション
  Widget _buildFeatureSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF0056FF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.50,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.50,
          ),
        ),
      ],
    );
  }
}