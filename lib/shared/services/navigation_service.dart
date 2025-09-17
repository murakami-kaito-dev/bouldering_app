import 'package:flutter/material.dart';
import '../../presentation/pages/gym_detail_page.dart';
import '../utils/type_converter.dart';

/// ナビゲーションサービス
///
/// 役割:
/// - ページ遷移ロジックの一元管理
/// - 型変換を含む遷移処理
/// - エラーハンドリング
///
/// クリーンアーキテクチャにおける位置づけ:
/// - 共通サービス層
/// - プレゼンテーション層から呼び出される
/// - ビジネスロジックとUIの橋渡し
class NavigationService {
  /// ジム詳細ページへの遷移
  ///
  /// [gymId] ドメイン層のint型ID
  /// [context] BuildContext
  static void navigateToGymDetail({
    required BuildContext context,
    required int gymId,
  }) {
    try {
      // int型IDをString型に変換（プレゼンテーション層の要求に合わせる）
      final gymIdString = TypeConverter.idToString(gymId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GymDetailPage(gymId: gymIdString),
        ),
      );
    } catch (e) {
      // エラーハンドリング
      _showErrorSnackBar(context, 'ページ遷移に失敗しました: $e');
    }
  }

  /// ジム名検索ページへの遷移
  static Future<void> navigateToGymSearch({
    required BuildContext context,
  }) async {
    // 動的インポートを避けるため、ここでは実装を簡略化
    // 実際の実装では適切なページインポートが必要
    await Navigator.pushNamed(context, '/gym/name-search');
  }

  /// エラー表示
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// ページを閉じる
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }

  /// 指定のルートまで戻る
  static void popUntil(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }
}
