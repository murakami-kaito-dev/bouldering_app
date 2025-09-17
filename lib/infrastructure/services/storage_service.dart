import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
// TODO: Mock環境で動作確認が必要な場合は、以下のインポートのコメントアウトを外してください
// import 'mock_storage_service.dart';

/// Google Cloud Storageサービスクラス
/// 
/// 役割:
/// - ファイルアップロード処理を担当
/// - ユーザーアイコンや投稿画像などのメディアファイル管理
/// - GCS認証とファイル操作の抽象化
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のサービスコンポーネント
/// - 外部ストレージサービスとの通信を担当
/// - Repository実装で使用される
class StorageService {
  final String bucketName;
  final String serviceAccountPath;
  
  // TODO: Mock環境での実装（必要に応じて有効化）
  // final MockStorageService _mockStorageService = MockStorageService();

  /// コンストラクタ
  /// 
  /// [bucketName] GCSバケット名
  /// [serviceAccountPath] サービスアカウントキーファイルのパス
  StorageService({
    required this.bucketName,
    required this.serviceAccountPath,
  });

  /// ユーザーアイコン画像をアップロード
  /// 
  /// [imageFile] アップロードする画像ファイル
  /// [userId] ユーザーID
  /// 
  /// 返り値:
  /// [String?] アップロード成功時は公開URL、失敗時はnull
  /// 
  /// 処理フロー:
  /// 1. サービスアカウント認証
  /// 2. ファイルのハッシュ値計算（重複防止）
  /// 3. GCSへのアップロード
  /// 4. 公開URLの生成
  Future<String?> uploadUserIcon(File imageFile, {required String userId}) async {
    try {
      // サービスアカウント認証の設定
      final credentials = await _getCredentials();
      final client = await clientViaServiceAccount(
        credentials,
        [gcs.StorageApi.devstorageFullControlScope],
      );

      final storage = gcs.StorageApi(client);
      
      // 拡張子を取得
      final extension = path.extension(imageFile.path);
      
      // 固定パス構造: v1/public/users/{uid}/profile/icon.{ext}
      // 同じパスで上書きされるため、古い画像は自動的に削除される
      final objectPath = 'v1/public/users/$userId/profile/icon$extension';

      // GCSへのアップロード実行（長期キャッシュ設定付き）
      final publicUrl = await _uploadFile(
        storage,
        imageFile,
        objectPath,
        // 1年間キャッシュ、変更不可を示すimmutableで最適化
        cacheControl: 'public, max-age=31536000, immutable',
      );

      // リソースクリーンアップ
      client.close();

      // キャッシュバスター付きURLを返す
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '$publicUrl?v=$timestamp';
    } catch (e) {
      throw StorageException('ユーザーアイコンのアップロードに失敗しました: $e');
    }
  }

  /// 投稿メディア（画像・動画）をアップロード
  /// 
  /// [mediaFile] アップロードするメディアファイル
  /// [mediaType] メディアタイプ（'image', 'video'など）
  /// [userId] ユーザーID
  /// [postUuid] 投稿UUID（クライアント側で生成済み）
  /// 
  /// 返り値:
  /// [Map<String, String>] アップロード情報（url, assetUuid, storagePrefix, mimeType）
  Future<Map<String, String>?> uploadPostMedia(File mediaFile, String mediaType, {required String userId, required String postUuid}) async {
    try {
      final credentials = await _getCredentials();
      final client = await clientViaServiceAccount(
        credentials,
        [gcs.StorageApi.devstorageFullControlScope],
      );

      final storage = gcs.StorageApi(client);

      // 日付情報を取得
      final now = DateTime.now();
      final yyyy = now.year.toString();
      final mm = now.month.toString().padLeft(2, '0');
      
      // assetUuid生成
      const uuid = Uuid();
      final assetUuid = uuid.v4();
      
      // 拡張子とMIMEタイプを取得
      final extension = path.extension(mediaFile.path);
      final mimeType = _getMimeType(extension);
      
      // 新しいパス構造: v1/public/users/{userId}/posts/{yyyy}/{mm}/{postUuid}/{assetUuid}/original.{ext}
      final objectPath = 'v1/public/users/$userId/posts/$yyyy/$mm/$postUuid/$assetUuid/original$extension';
      final storagePrefix = 'v1/public/users/$userId/posts/$yyyy/$mm/$postUuid/$assetUuid';

      // アップロード実行
      final publicUrl = await _uploadFile(
        storage,
        mediaFile,
        objectPath,
      );

      client.close();
      
      return {
        'url': publicUrl,
        'assetUuid': assetUuid,
        'storagePrefix': storagePrefix,
        'mimeType': mimeType,
      };
    } catch (e) {
      throw StorageException('メディアファイルのアップロードに失敗しました: $e');
    }
  }

  /// 複数のメディアファイルをアップロード
  /// 
  /// [mediaFiles] アップロードするメディアファイルのリスト
  /// [mediaType] メディアタイプ（'image', 'video'など）
  /// [userId] ユーザーID
  /// [postUuid] 投稿UUID（クライアント側で生成済み）
  /// 
  /// 返り値:
  /// [List<Map<String, String>>] アップロード成功したファイルの情報リスト
  Future<List<Map<String, String>>> uploadMultiplePostMedia(
    List<File> mediaFiles, 
    String mediaType, {
    required String userId,
    required String postUuid,
  }) async {
    final uploadedMedia = <Map<String, String>>[];
    
    try {
      // 並列でアップロード処理を実行
      final uploadFutures = mediaFiles.map((file) => 
        uploadPostMedia(file, mediaType, userId: userId, postUuid: postUuid)
      ).toList();
      
      final results = await Future.wait(uploadFutures);
      
      // 成功したアップロードの情報のみを返す
      for (final result in results) {
        if (result != null) {
          uploadedMedia.add(result);
        }
      }
      
      return uploadedMedia;
    } catch (e) {
      throw StorageException('複数メディアファイルのアップロードに失敗しました: $e');
    }
  }

  /// メディアファイルを削除
  /// 
  /// [mediaUrl] 削除するメディアのURL
  /// 
  /// 返り値:
  /// [bool] 削除成功時はtrue、失敗時はfalse
  Future<bool> deleteMedia(String mediaUrl) async {
    try {
      // URLからオブジェクトパスを抽出
      // https://storage.googleapis.com/{bucket}/{path} の形式から {path} を取得
      final uri = Uri.parse(mediaUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 2) {
        throw StorageException('無効なメディアURL: $mediaUrl');
      }
      
      // バケット名の次の部分からがオブジェクトパス
      final objectPath = pathSegments.sublist(1).join('/');
      
      // サービスアカウント認証の設定
      final credentials = await _getCredentials();
      final client = await clientViaServiceAccount(
        credentials,
        [gcs.StorageApi.devstorageFullControlScope],
      );

      final storage = gcs.StorageApi(client);
      
      // GCSからファイルを削除
      await storage.objects.delete(bucketName, objectPath);
      
      // リソースクリーンアップ
      client.close();
      
      return true;
    } catch (e) {
      throw StorageException('メディアファイルの削除に失敗しました: $e');
    }
  }

  // GCS関連メソッド
  
  /// サービスアカウント認証情報を取得
  /// 
  /// 返り値:
  /// [ServiceAccountCredentials] 認証情報
  Future<ServiceAccountCredentials> _getCredentials() async {
    try {
      final jsonString = await rootBundle.loadString(serviceAccountPath);
      return ServiceAccountCredentials.fromJson(jsonDecode(jsonString));
    } catch (e) {
      throw StorageException('認証情報の読み込みに失敗しました: $e');
    }
  }

  /// 拡張子からMIMEタイプを取得
  /// 
  /// [extension] ファイル拡張子
  /// 
  /// 返り値:
  /// [String] MIMEタイプ
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }


  /// GCSへのファイルアップロード実行
  /// 
  /// [storage] GCS APIクライアント
  /// [file] アップロードするファイル
  /// [objectPath] GCS上でのオブジェクトパス
  /// 
  /// 返り値:
  /// [String] 公開URL（キャッシュ制御メタデータ付き）
  Future<String> _uploadFile(
    gcs.StorageApi storage,
    File file,
    String objectPath,
    {String? cacheControl}
  ) async {
    try {
      // ファイルメディアの作成
      final media = gcs.Media(file.openRead(), file.lengthSync());

      // GCSオブジェクトの作成
      final object = gcs.Object()..name = objectPath;

      // キャッシュ制御の設定
      if (cacheControl != null) {
        object.cacheControl = cacheControl;
      }

      // オブジェクトに公開読み取り権限を設定
      object.acl = [
        gcs.ObjectAccessControl()
          ..entity = 'allUsers'
          ..role = 'READER',
      ];

      // アップロード実行（ACL付き）
      await storage.objects.insert(
        object,
        bucketName,
        uploadMedia: media,
      );

      // 公開URLの生成
      return 'https://storage.googleapis.com/$bucketName/$objectPath';
    } catch (e) {
      throw StorageException('ファイルアップロードに失敗しました: $e');
    }
  }
}

/// ストレージ例外クラス
/// 
/// 役割:
/// - ストレージ関連のエラー情報を保持
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}