import '../entities/moderation_result.dart';

/// テキストモデレーションサービス
///
/// 役割:
/// - テキストコンテンツの適切性を検証
/// - NGワード検出の抽象インターフェース
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のService Interface
/// - Infrastructure層で具体実装
abstract class TextModerationService {
  /// テキストを検証してNGワードをチェック
  ///
  /// [text] 検証対象のテキスト
  /// Returns: 検証結果を含むModerationResult
  ModerationResult checkText(String text);
  
  /// リアルタイム検証用の軽量チェック
  ///
  /// [text] 検証対象のテキスト
  /// Returns: NGワードが含まれている場合true
  bool hasNGWords(String text);
}