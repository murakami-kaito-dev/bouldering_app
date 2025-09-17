import 'dart:io';
import '../services/image_picker_service.dart';
import '../exceptions/app_exceptions.dart';

/// プロフィール画像選択ユースケース
/// 
/// 役割:
/// - プロフィール画像の選択処理
/// - バリデーションとエラーハンドリング
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - UseCase層のビジネスロジック
/// - ImagePickerServiceを利用
class SelectProfileImageUseCase {
  final ImagePickerService _imagePickerService;

  SelectProfileImageUseCase(this._imagePickerService);

  /// プロフィール画像を選択
  /// 
  /// 戻り値: 選択された画像ファイル（キャンセル時はnull）
  /// 
  /// 例外:
  /// [ValidationException] バリデーションエラー
  /// [DataFetchException] 画像選択エラー
  Future<File?> execute() async {
    try {
      // 画像選択ダイアログを表示してファイルを取得
      final imageFile = await _imagePickerService.showImageSourceDialog();
      
      if (imageFile != null) {
        // 選択された画像ファイルのバリデーションを実行
        await _validateImageFile(imageFile);
      }
      
      return imageFile;
    } catch (e) {
      // ValidationExceptionはそのまま再スロー
      if (e is ValidationException) {
        rethrow;
      }
      
      // その他のエラーはDataFetchExceptionでラップ
      throw DataFetchException(
        message: '画像の選択に失敗しました',
        originalError: e,
      );
    }
  }

  /// 画像ファイルのバリデーション
  /// 
  /// [imageFile] バリデーション対象の画像ファイル
  /// 
  /// 例外:
  /// [ValidationException] バリデーションエラー
  Future<void> _validateImageFile(File imageFile) async {
    // ファイル存在確認
    if (!await imageFile.exists()) {
      throw const ValidationException(
        message: '選択された画像ファイルが存在しません',
        errors: {'file': 'ファイルが見つかりません'},
        code: 'FILE_NOT_FOUND',
      );
    }

    // ファイルサイズ確認（10MB制限）
    final fileSize = await imageFile.length();
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB

    if (fileSize > maxSizeInBytes) {
      throw const ValidationException(
        message: '画像ファイルサイズが大きすぎます（10MB以下にしてください）',
        errors: {'file': 'ファイルサイズが制限を超えています'},
        code: 'FILE_TOO_LARGE',
      );
    }

    // ファイル拡張子確認
    final fileName = imageFile.path.toLowerCase();
    final supportedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    
    if (!supportedExtensions.any((ext) => fileName.endsWith(ext))) {
      throw const ValidationException(
        message: 'サポートされていない画像形式です（JPEG、PNG、WebPのみ対応）',
        errors: {'file': 'ファイル形式がサポートされていません'},
        code: 'UNSUPPORTED_FILE_FORMAT',
      );
    }
  }
}

/// 投稿用画像選択ユースケース
/// 
/// 役割:
/// - ツイート投稿用の複数画像選択処理
/// - バリデーションとエラーハンドリング
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - UseCase層のビジネスロジック
/// - ImagePickerServiceを利用
class SelectPostImagesUseCase {
  final ImagePickerService _imagePickerService;

  SelectPostImagesUseCase(this._imagePickerService);

  /// 投稿用画像を選択
  /// 
  /// [maxImages] 選択可能な最大画像数（デフォルト: 4）
  /// 
  /// 戻り値: 選択された画像ファイルのリスト
  /// 
  /// 例外:
  /// [ValidationException] バリデーションエラー
  /// [DataFetchException] 画像選択エラー
  Future<List<File>> execute({int maxImages = 4}) async {
    try {
      // 複数画像選択を実行
      final imageFiles = await _imagePickerService.pickMultipleImages(
        maxImages: maxImages,
      );
      
      if (imageFiles.isNotEmpty) {
        // 選択された各画像ファイルのバリデーションを実行
        for (final imageFile in imageFiles) {
          await _validateImageFile(imageFile);
        }
      }
      
      return imageFiles;
    } catch (e) {
      // ValidationExceptionはそのまま再スロー
      if (e is ValidationException) {
        rethrow;
      }
      
      // その他のエラーはDataFetchExceptionでラップ
      throw DataFetchException(
        message: '画像の選択に失敗しました',
        originalError: e,
      );
    }
  }

  /// 画像ファイルのバリデーション
  /// 
  /// [imageFile] バリデーション対象の画像ファイル
  /// 
  /// 例外:
  /// [ValidationException] バリデーションエラー
  Future<void> _validateImageFile(File imageFile) async {
    // ファイル存在確認
    if (!await imageFile.exists()) {
      throw const ValidationException(
        message: '選択された画像ファイルが存在しません',
        errors: {'file': 'ファイルが見つかりません'},
        code: 'FILE_NOT_FOUND',
      );
    }

    // ファイルサイズ確認（5MB制限）
    final fileSize = await imageFile.length();
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSizeInBytes) {
      throw const ValidationException(
        message: '画像ファイルサイズが大きすぎます（5MB以下にしてください）',
        errors: {'file': 'ファイルサイズが制限を超えています'},
        code: 'FILE_TOO_LARGE',
      );
    }

    // ファイル拡張子確認
    final fileName = imageFile.path.toLowerCase();
    final supportedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    
    if (!supportedExtensions.any((ext) => fileName.endsWith(ext))) {
      throw const ValidationException(
        message: 'サポートされていない画像形式です（JPEG、PNG、WebPのみ対応）',
        errors: {'file': 'ファイル形式がサポートされていません'},
        code: 'UNSUPPORTED_FILE_FORMAT',
      );
    }
  }
}