import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/user/user_avatar.dart';
import '../components/common/app_logo.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
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
      backgroundColor: AppColors.iwa,
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
                  color: AppColors.setsuri,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.wareme),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // アプリロゴ
                    const Center(child: AppLogo()),
                    const SizedBox(height: 16),

                    // 説明テキスト
                    Text(
                      'イワノボリタイに登録すると，ボル活がさらに充実します！登録は無料！',
                      textAlign: TextAlign.left,
                      style: AppText.body(size: 14),
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
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginOrSignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          '新規登録 / ログイン',
                          style: AppText.label(
                            size: 14,
                            color: AppColors.onKabeBlue,
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
          style: AppText.heading(size: 15),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.left,
          style: AppText.caption(size: 12),
        ),
      ],
    );
  }
}