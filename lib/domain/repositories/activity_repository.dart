import 'dart:io';
import '../entities/activity_post.dart';

/// アクティビティリポジトリインターフェース
/// 
/// 役割:
/// - アクティビティ投稿に関するデータアクセスの抽象化
/// - 投稿の作成、更新、削除、取得処理の定義
/// - 画像アップロード処理の定義
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のリポジトリインターフェース
/// - Infrastructure層の実装に依存しない抽象定義
/// - 依存性逆転の原則（DIP）を実現
abstract class ActivityRepository {
  /// 新しいアクティビティ投稿を作成
  /// 
  /// [activityPost] 投稿データ
  /// [mediaFiles] 投稿する画像ファイルリスト
  /// 
  /// 返り値:
  /// - 成功時: true
  /// - 失敗時: false
  Future<bool> createActivityPost(
    ActivityPost activityPost,
    List<File> mediaFiles,
  );

  /// アクティビティ投稿を更新
  /// 
  /// [activityPost] 更新する投稿データ
  /// [mediaFiles] 新規追加する画像ファイルリスト
  /// [existingUrls] 既存の画像URLリスト
  /// [originalUrls] 元の画像URLリスト（削除対象の特定に使用）
  /// 
  /// 返り値:
  /// - 成功時: true
  /// - 失敗時: false
  Future<bool> updateActivityPost(
    ActivityPost activityPost,
    List<File> mediaFiles,
    List<String> existingUrls,
    List<String> originalUrls,
  );

  /// アクティビティ投稿を削除
  /// 
  /// [postId] 削除する投稿のID
  /// 
  /// 返り値:
  /// - 成功時: true
  /// - 失敗時: false
  Future<bool> deleteActivityPost(int postId);

  /// 特定のアクティビティ投稿を取得
  /// 
  /// [postId] 取得する投稿のID
  /// 
  /// 返り値:
  /// - 成功時: ActivityPostオブジェクト
  /// - 失敗時またはデータが存在しない場合: null
  Future<ActivityPost?> getActivityPost(int postId);

  /// ユーザーのアクティビティ投稿一覧を取得
  /// 
  /// [userId] ユーザーID
  /// [limit] 取得件数上限（オプション）
  /// [offset] 取得開始位置（オプション）
  /// 
  /// 返り値:
  /// - 投稿リスト（投稿がない場合は空のリスト）
  Future<List<ActivityPost>> getUserActivityPosts(
    String userId, {
    int? limit,
    int? offset,
  });

  /// 特定のジムのアクティビティ投稿一覧を取得
  /// 
  /// [gymId] ジムID
  /// [limit] 取得件数上限（オプション）
  /// [offset] 取得開始位置（オプション）
  /// 
  /// 返り値:
  /// - 投稿リスト（投稿がない場合は空のリスト）
  Future<List<ActivityPost>> getGymActivityPosts(
    int gymId, {
    int? limit,
    int? offset,
  });

  /// 全てのアクティビティ投稿一覧を取得
  /// 
  /// [limit] 取得件数上限（オプション）
  /// [offset] 取得開始位置（オプション）
  /// 
  /// 返り値:
  /// - 投稿リスト（投稿がない場合は空のリスト）
  Future<List<ActivityPost>> getAllActivityPosts({
    int? limit,
    int? offset,
  });

  /// 画像ファイルをクラウドストレージにアップロード
  /// 
  /// [file] アップロードする画像ファイル
  /// 
  /// 返り値:
  /// - 成功時: アップロードされた画像の公開URL
  /// - 失敗時: null
  Future<String?> uploadImage(File file);

  /// 投稿に関連する画像を削除
  /// 
  /// [postId] 投稿ID
  /// [imageUrl] 削除する画像のURL
  /// 
  /// 返り値:
  /// - 成功時: true
  /// - 失敗時: false
  Future<bool> deletePostImage(int postId, String imageUrl);

  /// 投稿に画像URLを関連付け
  /// 
  /// [postId] 投稿ID
  /// [imageUrl] 画像URL
  /// [mediaType] メディアタイプ（'photo', 'video'など）
  /// 
  /// 返り値:
  /// - 成功時: true
  /// - 失敗時: false
  Future<bool> addPostImage(int postId, String imageUrl, String mediaType);

  /// 特定の投稿に関連する画像URL一覧を取得
  /// 
  /// [postId] 投稿ID
  /// 
  /// 返り値:
  /// - 画像URLのリスト（画像がない場合は空のリスト）
  Future<List<String>> getPostImages(int postId);
}