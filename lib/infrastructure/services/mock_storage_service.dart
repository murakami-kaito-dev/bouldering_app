import 'dart:async';
import 'dart:io';
import 'dart:math';

/// Google Cloud Storageのモック実装
/// 
/// 役割:
/// - ファイルアップロード処理のシミュレート
/// - 仮のダウンロードURLの生成
/// - ストレージ操作の成功/失敗シミュレーション
class MockStorageService {
  static final MockStorageService _instance = MockStorageService._internal();
  factory MockStorageService() => _instance;
  MockStorageService._internal();

  // アップロードされたファイルの仮URL管理
  final Map<String, String> _uploadedFiles = {};
  
  // 仮のストレージベースURL
  static const String _mockStorageBaseUrl = 'https://storage.mock.googleapis.com/mock-bucket';

  /// ユーザーアイコンをアップロード
  Future<String?> uploadUserIcon(File imageFile, {required String userId}) async {
    try {
      // アップロード処理をシミュレート
      await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
      
      // ファイルサイズチェックのシミュレート
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB制限
        throw MockStorageException(
          code: 'file-too-large',
          message: 'ファイルサイズが大きすぎます（最大5MB）',
        );
      }
      
      // 仮のファイルパスを生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'user_icons/icon_${timestamp}_${Random().nextInt(10000)}.jpg';
      final mockUrl = '$_mockStorageBaseUrl/$fileName';
      
      // アップロード成功として記録
      _uploadedFiles[fileName] = mockUrl;
      
      return mockUrl;
    } catch (e) {
      if (e is MockStorageException) rethrow;
      
      // その他のエラー
      throw MockStorageException(
        code: 'upload-failed',
        message: 'アップロードに失敗しました',
      );
    }
  }

  /// 投稿メディアをアップロード
  Future<String?> uploadPostMedia(File mediaFile, String mediaType, {required String userId, String? postId}) async {
    try {
      // アップロード処理をシミュレート
      await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1200)));
      
      // メディアタイプの検証
      if (mediaType != 'image' && mediaType != 'video') {
        throw MockStorageException(
          code: 'invalid-media-type',
          message: '無効なメディアタイプです',
        );
      }
      
      // ファイルサイズチェックのシミュレート
      final fileSize = await mediaFile.length();
      final maxSize = mediaType == 'image' ? 10 * 1024 * 1024 : 100 * 1024 * 1024; // 画像10MB、動画100MB
      
      if (fileSize > maxSize) {
        throw MockStorageException(
          code: 'file-too-large',
          message: 'ファイルサイズが大きすぎます',
        );
      }
      
      // 仮のファイルパスを生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = mediaType == 'image' ? 'jpg' : 'mp4';
      final fileName = 'posts/${mediaType}s/${mediaType}_${timestamp}_${Random().nextInt(10000)}.$extension';
      final mockUrl = '$_mockStorageBaseUrl/$fileName';
      
      // アップロード成功として記録
      _uploadedFiles[fileName] = mockUrl;
      
      return mockUrl;
    } catch (e) {
      if (e is MockStorageException) rethrow;
      
      // その他のエラー
      throw MockStorageException(
        code: 'upload-failed',
        message: 'アップロードに失敗しました',
      );
    }
  }

  /// 複数の投稿メディアを一括アップロード
  Future<List<String>> uploadMultiplePostMedia(List<File> mediaFiles, String mediaType, {required String userId, String? postId}) async {
    final uploadedUrls = <String>[];
    
    // 並列アップロードをシミュレート
    final uploadFutures = mediaFiles.map((file) => uploadPostMedia(file, mediaType, userId: userId, postId: postId));
    final results = await Future.wait(uploadFutures);
    
    for (final url in results) {
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  /// メディアを削除
  Future<bool> deleteMedia(String mediaUrl) async {
    try {
      // 削除処理をシミュレート
      await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(500)));
      
      // URLからファイル名を抽出
      final uri = Uri.tryParse(mediaUrl);
      if (uri == null) {
        throw MockStorageException(
          code: 'invalid-url',
          message: '無効なURLです',
        );
      }
      
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) {
        throw MockStorageException(
          code: 'file-not-found',
          message: 'ファイルが見つかりません',
        );
      }
      
      // ファイル名を構築
      final fileName = pathSegments.sublist(1).join('/'); // mock-bucketを除外
      
      // ファイルが存在するか確認
      if (!_uploadedFiles.containsKey(fileName)) {
        throw MockStorageException(
          code: 'file-not-found',
          message: 'ファイルが見つかりません',
        );
      }
      
      // 削除成功
      _uploadedFiles.remove(fileName);
      return true;
      
    } catch (e) {
      if (e is MockStorageException) rethrow;
      
      // その他のエラー
      throw MockStorageException(
        code: 'delete-failed',
        message: '削除に失敗しました',
      );
    }
  }

  /// アップロードされたファイルの一覧を取得（デバッグ用）
  Map<String, String> get uploadedFiles => Map.unmodifiable(_uploadedFiles);

  /// モックデータをリセット（テスト用）
  void reset() {
    _uploadedFiles.clear();
  }
}

/// Google Cloud StorageのExceptionのモック
class MockStorageException implements Exception {
  final String code;
  final String message;

  MockStorageException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'MockStorageException: [$code] $message';
}

/// ストレージエラーコード定数
class MockStorageErrorCodes {
  static const String fileTooLarge = 'file-too-large';
  static const String invalidMediaType = 'invalid-media-type';
  static const String uploadFailed = 'upload-failed';
  static const String deleteFailed = 'delete-failed';
  static const String fileNotFound = 'file-not-found';
  static const String invalidUrl = 'invalid-url';
  static const String permissionDenied = 'permission-denied';
  static const String quotaExceeded = 'quota-exceeded';
}