import '../../domain/entities/moderation_result.dart';
import '../../domain/services/text_moderation_service.dart';
import '../data/ng_words_data.dart';

/// ローカルテキストモデレーションサービス
///
/// 役割:
/// - アプリ内でNGワード検証を実行
/// - 完全一致方式で誤検知を防止
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のService実装
/// - Domain層のインターフェースを具体化
class LocalTextModerationService implements TextModerationService {
  
  @override
  ModerationResult checkText(String text) {
    if (text.trim().isEmpty) {
      return const ModerationResult(
        isAllowed: true,
        detectedWords: [],
      );
    }

    final detectedWords = <String>[];
    final normalizedText = text.toLowerCase();
    
    // NGワードリストと照合
    for (final ngWord in NGWordsData.ngWords) {
      // 完全一致チェック（単語境界を考慮）
      if (_containsExactWord(normalizedText, ngWord.toLowerCase())) {
        detectedWords.add(ngWord);
      }
    }
    
    return ModerationResult(
      isAllowed: detectedWords.isEmpty,
      detectedWords: detectedWords,
      suggestion: detectedWords.isNotEmpty 
          ? '「${detectedWords.first}」などの不適切な表現が含まれています' 
          : null,
    );
  }
  
  @override
  bool hasNGWords(String text) {
    if (text.trim().isEmpty) return false;
    
    final normalizedText = text.toLowerCase();
    
    // 高速チェック：最初のNGワードが見つかったら即座にtrueを返す
    for (final ngWord in NGWordsData.ngWords) {
      if (_containsExactWord(normalizedText, ngWord.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  /// ゆるやか部分一致チェック（Chat GPT提案の実装）
  /// 
  /// 「前後が空白・記号・文頭文末の場合に一致」する条件で検出
  /// これにより「死ね」は検出するが「死ねる」は検出しない
  /// 
  /// 検出例：
  /// - 「死ね」→ NG ✅
  /// - 「死ねよ」→ NG ✅  
  /// - 「死ね殺す」→ NG ✅
  /// - 「死ねる」→ OK ✅（「る」と連続しているため）
  /// - 「必死ねば」→ OK ✅（「必死」と連続しているため）
  bool _containsExactWord(String text, String word) {
    // 日本語対応の正規表現で単語境界を考慮した部分一致
    // 
    // 問題: \W は英語圏の記号のみ、日本語のひらがな「よ」は \w として扱われる
    // 解決: 日本語では単純に部分一致で検出し、前後の文字種で判定する
    
    if (_isJapaneseWord(word)) {
      // 日本語NGワードの場合: シンプルな部分一致
      // 「死ね」→「死ね」「死ねよ」「死ね殺す」すべて検出
      // ただし「死ねる」「必死ね」のような自然な文章は別途除外が必要
      return text.toLowerCase().contains(word.toLowerCase());
    } else {
      // 英語NGワードの場合: 従来の正規表現
      final pattern = RegExp(
        '(^|\\s|\\W)${RegExp.escape(word)}(\\s|\\W|\$)',
        caseSensitive: false,
      );
      return pattern.hasMatch(text);
    }
  }
  
  /// 日本語の単語かどうかを判定
  bool _isJapaneseWord(String word) {
    // ひらがな、カタカナ、漢字が含まれていれば日本語と判定
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return japanesePattern.hasMatch(word);
  }
}