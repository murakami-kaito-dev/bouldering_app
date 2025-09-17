import 'dart:io';
import '../../domain/repositories/storage_repository.dart';
import '../services/storage_service.dart';

/// ストレージリポジトリ実装クラス
///
/// 役割:
/// - Domain層で定義されたStorageRepositoryインターフェースの実装
/// - StorageServiceを使用してファイルアップロード処理を実行
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のRepository実装
/// - Domain層のRepository抽象クラスに依存（依存関係逆転の原則）
/// - StorageServiceを利用して具体的な処理を実行
class StorageRepositoryImpl implements StorageRepository {
  final StorageService _storageService;

  /// コンストラクタ
  ///
  /// [_storageService] ストレージサービス
  StorageRepositoryImpl(this._storageService);

  /// ユーザーアイコン画像をアップロード
  @override
  Future<String?> uploadUserIcon(File imageFile,
      {required String userId}) async {
    try {
      return await _storageService.uploadUserIcon(imageFile, userId: userId);
    } catch (e) {
      // ユーザーアイコンアップロード失敗
      return null;
    }
  }

  /// 投稿メディア（画像・動画）をアップロード
  @override
  Future<Map<String, String>?> uploadPostMedia(File mediaFile, String mediaType,
      {required String userId, required String postUuid}) async {
    try {
      return await _storageService.uploadPostMedia(mediaFile, mediaType,
          userId: userId, postUuid: postUuid);
    } catch (e) {
      // 投稿メディアアップロード失敗
      return null;
    }
  }

  /// 複数の投稿メディアを一括アップロード
  @override
  Future<List<Map<String, String>>> uploadMultiplePostMedia(
      List<File> mediaFiles, String mediaType,
      {required String userId, required String postUuid}) async {
    try {
      return await _storageService.uploadMultiplePostMedia(
          mediaFiles, mediaType,
          userId: userId, postUuid: postUuid);
    } catch (e) {
      // 複数メディアアップロード失敗
      return [];
    }
  }

  /// アップロードしたメディアを削除
  @override
  Future<bool> deleteMedia(String mediaUrl) async {
    try {
      return await _storageService.deleteMedia(mediaUrl);
    } catch (e) {
      // メディア削除失敗
      return false;
    }
  }
}
