import '../entities/moderation_result.dart';
import '../services/text_moderation_service.dart';

/// 投稿コンテンツ検証UseCase
///
/// 役割:
/// - 投稿前のテキスト検証ビジネスロジック
/// - NGワード検出と投稿可否判定
/// - UIから独立したビジネスルールの実装
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のUseCase
/// - ビジネスルールの実行
/// 
/// 【このクラスが行うビジネスルール】
/// 1. 空文字の場合は検証をスキップ（投稿可能）
/// 2. NGワードが含まれている場合は投稿不可
/// 3. 適切なエラーメッセージの生成
/// 
/// 【なぜUseCaseが必要？】
/// - 投稿画面（ActivityPostPage）にビジネスロジックを書かない
/// - 編集画面など他の場所でも同じルールを使い回せる
/// - ビジネスロジックのテストが独立して書ける
class ValidatePostContentUseCase {
  final TextModerationService _moderationService;

  ValidatePostContentUseCase(this._moderationService);

  /// 投稿コンテンツを検証
  ///
  /// [content] 投稿内容
  /// Returns: 検証結果（投稿可否、検出されたNGワード、エラーメッセージ）
  /// 
  /// 【処理フロー】
  /// 1. 空文字チェック → 空なら投稿OK
  /// 2. NGワードチェック → _moderationServiceに委譲
  /// 3. 結果を判定 → NGワードがあれば投稿NG
  /// 4. エラーメッセージ生成 → UIに表示する文言を設定
  ModerationResult execute(String content) {
    // ビジネスルール1: 空文字の場合は検証をスキップ
    if (content.trim().isEmpty) {
      return const ModerationResult(
        isAllowed: true,
        detectedWords: [],
      );
    }

    // ビジネスルール2: NGワードチェック
    // 実際のチェック処理はTextModerationServiceに委譲
    // （LocalかServerかはProviderで切り替え可能）
    final result = _moderationService.checkText(content);
    
    // ビジネスルール3: 検出されたワードがある場合は投稿不可
    return ModerationResult(
      isAllowed: !result.hasViolations,
      detectedWords: result.detectedWords,
      suggestion: result.hasViolations 
          ? '不適切な表現が含まれています。修正してください。' 
          : null,
    );
  }

  /// リアルタイムチェック用の簡易検証
  /// 
  /// 文字入力中の軽量チェック用
  /// パフォーマンスを重視して、詳細情報は返さない
  /// 
  /// [content] チェック対象のテキスト
  /// Returns: true = 投稿可能, false = NGワードあり
  bool quickCheck(String content) {
    if (content.trim().isEmpty) return true;
    return !_moderationService.hasNGWords(content);
  }
}