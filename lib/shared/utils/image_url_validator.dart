/// 画像URL検証ユーティリティ
///
/// 役割:
/// - 画像URLの有効性を検証する共通機能
/// - プレースホルダー画像の除外
/// - 無効なURLのフィルタリング
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Shared層のユーティリティ
/// - ドメイン非依存の共通機能
/// - 複数のPresentation層コンポーネントから利用
class ImageUrlValidator {
  /// URL有効性チェック
  /// 
  /// [url] 検証対象のURL
  /// 戻り値: 有効なHTTP URLの場合true
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return Uri.tryParse(url) != null && url.startsWith('http');
  }

  /// プレースホルダー画像URLかチェック
  /// 
  /// [url] 検証対象のURL
  /// 戻り値: プレースホルダー画像の場合true
  static bool isPlaceholderUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('via.placeholder.com') || url.contains('placeholder');
  }

  /// 表示可能な画像URLかチェック
  /// 
  /// [url] 検証対象のURL
  /// 戻り値: 表示可能な画像URLの場合true
  static bool isValidImageUrl(String? url) {
    return isValidUrl(url) && !isPlaceholderUrl(url);
  }

  /// 有効な画像URLのみをフィルタリング
  /// 
  /// [urls] フィルタリング対象のURLリスト
  /// 戻り値: 有効な画像URLのみのリスト
  static List<String> filterValidImageUrls(List<String> urls) {
    return urls.where((url) => isValidImageUrl(url)).toList();
  }
}