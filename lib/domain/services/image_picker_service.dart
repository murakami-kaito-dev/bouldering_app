import 'dart:io';

/// 画像選択サービスのインターフェース
/// 
/// 役割:
/// - ギャラリーやカメラからの画像選択
/// - 単一画像・複数画像の選択対応
/// - プラットフォーム間の抽象化
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Domain層のサービスインターフェース
/// - Infrastructure層で具体的な実装を提供
abstract class ImagePickerService {
  /// ギャラリーから単一画像を選択
  /// 
  /// 戻り値: 選択された画像ファイル（キャンセル時はnull）
  Future<File?> pickSingleImage();

  /// ギャラリーから複数画像を選択
  /// 
  /// [maxImages] 選択可能な最大画像数（デフォルト: 4）
  /// 
  /// 戻り値: 選択された画像ファイルのリスト
  Future<List<File>> pickMultipleImages({int maxImages = 4});

  /// カメラから画像を撮影
  /// 
  /// 戻り値: 撮影された画像ファイル（キャンセル時はnull）
  Future<File?> takePicture();

  /// 画像選択方法を選択するダイアログを表示
  /// 
  /// 戻り値: 選択された画像ファイル（キャンセル時はnull）
  Future<File?> showImageSourceDialog();
}