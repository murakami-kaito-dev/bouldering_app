import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shared/config/firebase_options_dev.dart';

/// 強制ログアウト用の特別なmain
///
/// 使用方法: flutter run --flavor "Runner Dev" -t lib/main_force_logout.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 強制的にサインアウト
  debugPrint('現在のユーザー: ${FirebaseAuth.instance.currentUser?.uid}');
  debugPrint('サインアウト実行中...');

  try {
    await FirebaseAuth.instance.signOut();
    debugPrint('✅ サインアウト完了');
  } catch (e) {
    debugPrint('エラー: $e');
  }

  // 確認
  debugPrint('サインアウト後のユーザー: ${FirebaseAuth.instance.currentUser?.uid}');

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              '強制ログアウト完了',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('このアプリを閉じて、通常のアプリを起動してください'),
          ],
        ),
      ),
    ),
  ));
}
