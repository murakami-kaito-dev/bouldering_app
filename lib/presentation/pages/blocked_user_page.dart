import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF7FF),
        surfaceTintColor: const Color(0xFFFEF7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ユーザー',
          style: TextStyle(
            color: Colors.black,
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
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(
              '表示できないユーザーです',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'このユーザーはブロック中のため、\nプロフィールを表示できません。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
