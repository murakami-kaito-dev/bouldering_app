/// コンテンツモデレーション結果
///
/// 役割:
/// - テキストの検証結果を表現
/// - NGワード検出情報を保持
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のEntity
/// - ビジネスルールの表現
class ModerationResult {
  /// 投稿可能かどうか
  final bool isAllowed;
  
  /// 検出されたNGワードリスト
  final List<String> detectedWords;
  
  /// ユーザーへの提案メッセージ
  final String? suggestion;

  const ModerationResult({
    required this.isAllowed,
    required this.detectedWords,
    this.suggestion,
  });

  /// 検出されたNGワードがある場合のみtrueを返す
  bool get hasViolations => detectedWords.isNotEmpty;

  /// 最初に検出されたNGワードを返す（エラー表示用）
  String? get firstDetectedWord => 
      detectedWords.isNotEmpty ? detectedWords.first : null;
}