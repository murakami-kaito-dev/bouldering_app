import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// ブロック済みユーザー表示ページ
///
/// 役割:
/// - ブロック済みユーザーのプロフィールにアクセスした際の専用画面
/// - 「表示できないユーザーです」メッセージの表示
/// - シンプルで軽量な構成
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のPage
/// - ブロック機能の一部として、単一の責任を持つ
class BlockedUserPage extends StatelessWidget {
  const BlockedUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iwa,
      appBar: AppBar(
        backgroundColor: AppColors.iwa,
        surfaceTintColor: AppColors.iwa,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.chalk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ユーザー',
          style: TextStyle(
            color: AppColors.chalk,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: AppColors.sunabokori,
            ),
            SizedBox(height: 24),
            Text(
              '表示できないユーザーです',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.chalk,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'このユーザーはブロック中のため、\nプロフィールを表示できません。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.sunabokori,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
