import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/services/image_picker_service.dart';

/// ImagePickerServiceの実装クラス
/// 
/// 役割:
/// - image_pickerパッケージを使用した画像選択機能の実装
/// - エラーハンドリングとプラットフォーム固有の処理
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Infrastructure層のサービス実装
/// - Domain層のImagePickerServiceインターフェースを実装
class ImagePickerServiceImpl implements ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final BuildContext? context;

  /// コンストラクタ
  /// 
  /// [context] ダイアログ表示用のBuildContext（オプション）
  ImagePickerServiceImpl({this.context});

  @override
  Future<File?> pickSingleImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw ImagePickerException('画像の選択に失敗しました: $e');
    }
  }

  @override
  Future<List<File>> pickMultipleImages({int maxImages = 4}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      // 最大枚数を制限
      final limitedImages = images.take(maxImages).toList();
      
      return limitedImages.map((image) => File(image.path)).toList();
    } catch (e) {
      throw ImagePickerException('画像の選択に失敗しました: $e');
    }
  }

  @override
  Future<File?> takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw ImagePickerException('写真の撮影に失敗しました: $e');
    }
  }

  @override
  Future<File?> showImageSourceDialog() async {
    if (context == null) {
      // contextがない場合はデフォルトでギャラリーを使用
      return await pickSingleImage();
    }

    final result = await showDialog<String>(
      context: context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('画像を選択'),
          content: const Text('画像の選択方法を選んでください'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('gallery'),
              child: const Text('ギャラリーから選択'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('camera'),
              child: const Text('カメラで撮影'),
            ),
          ],
        );
      },
    );

    if (result == null) return null;

    switch (result) {
      case 'gallery':
        return await pickSingleImage();
      case 'camera':
        return await takePicture();
      default:
        return null;
    }
  }
}

/// 画像選択例外クラス
/// 
/// 役割:
/// - 画像選択関連のエラー情報を保持
class ImagePickerException implements Exception {
  final String message;

  ImagePickerException(this.message);

  @override
  String toString() => 'ImagePickerException: $message';
}