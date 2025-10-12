import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/post_moderation_provider.dart';

/// NGワード検証の共通ヘルパークラス
/// 
/// 役割:
/// - NGワードチェック + エラーダイアログ表示を共通化
/// - 各画面での重複コードを削減
/// - 一貫したユーザー体験を提供
class NGWordValidator {
  
  /// NGワードチェック + ダイアログ表示の共通処理
  /// 
  /// パラメータ:
  /// - context: ダイアログ表示用のBuildContext
  /// - ref: Riverpod WidgetRef
  /// - content: チェック対象のテキスト
  /// - fieldName: エラーメッセージに表示するフィールド名（例：「ユーザー名」「投稿内容」）
  /// 
  /// 戻り値:
  /// - true: 問題なし（処理続行可能）
  /// - false: NGワード検出（処理中断）
  static Future<bool> validateWithDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String content,
    required String fieldName,
  }) async {
    // 空文字チェック（空の場合はスキップ）
    if (content.trim().isEmpty) {
      return true;
    }
    
    try {
      // NGワードチェック実行
      final moderationService = ref.read(postModerationProvider.notifier);
      final moderationResult = moderationService.validateContent(content.trim());
      
      // NGワードが検出された場合
      if (!moderationResult.isAllowed) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('${fieldName}に不適切な内容が含まれています'),
              content: Text('${fieldName}に使用できない言葉が含まれています。\n内容を修正してください。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return false; // 処理中断
      }
      
      return true; // 問題なし
      
    } catch (e) {
      // エラー時は処理を続行（フィルタリングの失敗で機能が使えなくなるのを防ぐ）
      debugPrint('NGワードチェックでエラーが発生しました: $e');
      return true;
    }
  }
  
  /// 複数フィールドの一括チェック
  /// 
  /// パラメータ:
  /// - context: ダイアログ表示用のBuildContext
  /// - ref: Riverpod WidgetRef
  /// - fields: フィールド名とコンテンツのマップ
  /// 
  /// 戻り値:
  /// - true: 全フィールド問題なし
  /// - false: いずれかのフィールドでNGワード検出
  static Future<bool> validateMultipleFields({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, String> fields,
  }) async {
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final content = entry.value;
      
      final isValid = await validateWithDialog(
        context: context,
        ref: ref,
        content: content,
        fieldName: fieldName,
      );
      
      if (!isValid) {
        return false; // 最初のNGワードで中断
      }
    }
    
    return true; // 全フィールド問題なし
  }
}