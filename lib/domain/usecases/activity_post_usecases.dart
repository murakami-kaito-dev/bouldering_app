import 'dart:io';
import '../repositories/tweet_repository.dart';
import '../repositories/storage_repository.dart';
import 'package:uuid/uuid.dart';

/// アクティビティ投稿に関するユースケース
/// 
/// 役割:
/// - ボルダリングアクティビティの投稿処理
/// - 画像アップロード処理
/// - 投稿データの検証
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のユースケース
/// - アプリケーションのビジネスロジックを定義
/// - Presentation層から呼び出される
class ActivityPostUseCase {
  final TweetRepository _repository;
  final StorageRepository _storageRepository;

  /// コンストラクタ
  /// 
  /// [_repository] ツイートリポジトリ（アクティビティ投稿処理に使用）
  /// [_storageRepository] ストレージリポジトリ（画像アップロード処理に使用）
  ActivityPostUseCase(this._repository, this._storageRepository);

  /// 新規アクティビティ投稿
  /// 
  /// [userId] ユーザーID
  /// [gymId] ジムID
  /// [visitedDate] 訪問日
  /// [tweetContents] 投稿内容
  /// [mediaFiles] 投稿する画像ファイルリスト
  /// 
  /// 返り値:
  /// - 成功時: true
  /// - 失敗時: false
  Future<bool> postActivity({
    required String userId,
    required int gymId,
    required DateTime visitedDate,
    required String tweetContents,
    required List<File> mediaFiles,
  }) async {
    try {
      // バリデーション
      if (userId.trim().isEmpty) {
        throw Exception('ユーザーIDが必要です');
      }
      if (gymId <= 0) {
        throw Exception('有効なジムIDが必要です');
      }
      if (mediaFiles.length > 5) {
        throw Exception('画像は最大5枚まで投稿できます');
      }

      // postUuidをクライアント側で生成
      const uuid = Uuid();
      final postUuid = uuid.v4();

      // 画像をアップロード（新しいパス構造で）
      final uploadedMedia = await _storageRepository.uploadMultiplePostMedia(
        mediaFiles,
        'image',
        userId: userId,
        postUuid: postUuid,
      );

      // リポジトリを通じて投稿処理を実行（拡張されたmedia情報と共に）
      return await _repository.createTweet(
        userId: userId,
        gymId: gymId,
        content: tweetContents,
        visitedDate: visitedDate,
        postUuid: postUuid,
        mediaData: uploadedMedia,
      );
    } catch (e) {
      // エラー発生時はfalseを返す
      return false;
    }
  }

  /// アクティビティ投稿を更新
  /// 
  /// [tweetId] ツイートID
  /// [userId] ユーザーID
  /// [gymId] ジムID
  /// [visitedDate] 訪問日
  /// [tweetContents] 投稿内容
  /// [mediaFiles] 新規追加する画像ファイルリスト
  /// [existingUrls] 既存の画像URLリスト
  /// [originalUrls] 元の画像URLリスト（削除対象の特定に使用）
  /// 
  /// 返り値:
  /// - 成功時: true
  /// - 失敗時: false
  Future<bool> updateActivity({
    required int tweetId,
    required String userId,
    required int gymId,
    required DateTime visitedDate,
    required String tweetContents,
    required List<File> mediaFiles,
    required List<String> existingUrls,
    required List<String> originalUrls,
  }) async {
    try {
      // バリデーション
      if (tweetId <= 0) {
        throw Exception('有効なツイートIDが必要です');
      }
      if (userId.trim().isEmpty) {
        throw Exception('ユーザーIDが必要です');
      }
      if (gymId <= 0) {
        throw Exception('有効なジムIDが必要です');
      }
      if (existingUrls.length + mediaFiles.length > 5) {
        throw Exception('画像は最大5枚まで投稿できます');
      }

      // 削除するメディアURLを特定
      final urlsToDelete = originalUrls.where((url) => !existingUrls.contains(url)).toList();
      
      // 削除処理を実行
      for (final url in urlsToDelete) {
        await _storageRepository.deleteMedia(url);
      }
      
      // 新規画像がある場合、既存のpost_uuidを取得して再利用
      List<String> allMediaUrls = [...existingUrls];
      
      if (mediaFiles.isNotEmpty) {
        // 既存の画像URLから既存のpost_uuidを抽出
        // 既存画像がない場合のみ新しいpost_uuidを生成
        String postUuidToUse;
        if (existingUrls.isNotEmpty) {
          // 既存画像からpost_uuidを再利用
          postUuidToUse = _extractPostUuidFromUrl(existingUrls.first);
        } else {
          // 既存画像がない場合は新しいpost_uuidを生成
          const uuid = Uuid();
          postUuidToUse = uuid.v4();
        }
        
        // 新規画像をアップロード（既存のpost_uuidまたは新規post_uuidを使用）
        final newUploadedMedia = await _storageRepository.uploadMultiplePostMedia(
          mediaFiles,
          'image',
          userId: userId,
          postUuid: postUuidToUse,
        );
        
        // 新しくアップロードされた画像のURLを追加
        final newUrls = newUploadedMedia.map((data) => data['url'] as String).toList();
        allMediaUrls.addAll(newUrls);
      }
      
      // リポジトリを通じて更新処理を実行
      return await _repository.updateTweet(
        tweetId: tweetId,
        userId: userId,
        gymId: gymId,
        content: tweetContents,
        visitedDate: visitedDate,
        mediaUrls: allMediaUrls,
      );
    } catch (e) {
      // エラー発生時はfalseを返す
      return false;
    }
  }

  /// 投稿内容の事前検証
  /// 
  /// [tweetContents] 投稿内容
  /// [mediaFiles] 画像ファイルリスト
  /// 
  /// 返り値:
  /// - 有効: true
  /// - 無効: false
  bool validatePostContent({
    required String tweetContents,
    required List<File> mediaFiles,
  }) {
    // 投稿内容の長さチェック
    if (tweetContents.length > 400) {
      return false;
    }

    // 画像枚数チェック
    if (mediaFiles.length > 5) {
      return false;
    }

    // 画像ファイルの存在チェック
    for (final file in mediaFiles) {
      if (!file.existsSync()) {
        return false;
      }
    }

    return true;
  }

  /// 画像URLからpost_uuidを抽出
  /// 
  /// [url] 画像URL（例: https://storage.googleapis.com/.../posts/2025/09/{post_uuid}/...）
  /// 
  /// 返り値:
  /// - 抽出されたpost_uuid
  /// - 抽出できない場合は新しいUUIDを生成
  /// 
  /// URL構造: .../posts/{year}/{month}/{post_uuid}/{asset_uuid}/original.jpeg
  String _extractPostUuidFromUrl(String url) {
    try {
      // URLのパス部分を取得してpost_uuidを抽出
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // posts/{year}/{month}/{post_uuid}/ の形式からpost_uuidを抽出
      final postsIndex = pathSegments.indexOf('posts');
      if (postsIndex != -1 && postsIndex + 3 < pathSegments.length) {
        final extractedUuid = pathSegments[postsIndex + 3]; // posts の後の3番目がpost_uuid
        
        // UUIDの形式をチェック（36文字、ハイフンを含む形式）
        final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
        if (uuidRegex.hasMatch(extractedUuid)) {
          // UUID形式が正しければ返す
          return extractedUuid;
        }
      }
      
      // 抽出できない場合は新しいUUIDを生成
      const uuid = Uuid();
      return uuid.v4();
    } catch (e) {
      // エラーの場合も新しいUUIDを生成
      const uuid = Uuid();
      return uuid.v4();
    }
  }
}