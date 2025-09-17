import 'dart:io';

/// ストレージリポジトリ抽象クラス
/// 
/// 役割:
/// - ファイルアップロード処理の抽象化
/// - Domain層で定義されるインターフェース
/// - Infrastructure層で具体的な実装を提供
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のRepository（抽象クラス）
/// - UseCase層から使用される
/// - Infrastructure層で実装される（依存関係逆転の原則）
abstract class StorageRepository {
  /// ユーザーアイコン画像をアップロード
  /// 
  /// [imageFile] アップロードする画像ファイル
  /// [userId] ユーザーID
  /// 
  /// 返り値:
  /// [String?] アップロード成功時は公開URL、失敗時はnull
  Future<String?> uploadUserIcon(File imageFile, {required String userId});

  /// 投稿メディア（画像・動画）をアップロード
  /// 
  /// [mediaFile] アップロードするメディアファイル
  /// [mediaType] メディアタイプ（'photo', 'video'など）
  /// [userId] ユーザーID
  /// [postUuid] 投稿UUID（クライアント側で生成済み）
  /// 
  /// 返り値:
  /// [Map<String, String>?] アップロード成功時は画像情報、失敗時はnull
  Future<Map<String, String>?> uploadPostMedia(File mediaFile, String mediaType, {required String userId, required String postUuid});

  /// 複数の投稿メディアを一括アップロード
  /// 
  /// [mediaFiles] アップロードするメディアファイルのリスト
  /// [mediaType] メディアタイプ（'photo', 'video'など）
  /// [userId] ユーザーID
  /// [postUuid] 投稿UUID（クライアント側で生成済み）
  /// 
  /// 返り値:
  /// [List<Map<String, String>>] アップロード成功したファイルの情報リスト
  Future<List<Map<String, String>>> uploadMultiplePostMedia(List<File> mediaFiles, String mediaType, {required String userId, required String postUuid});

  /// アップロードしたメディアを削除
  /// 
  /// [mediaUrl] 削除するメディアのURL
  /// 
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  Future<bool> deleteMedia(String mediaUrl);
}