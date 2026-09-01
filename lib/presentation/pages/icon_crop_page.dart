import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// プロフィールアイコンのトリミングページ
///
/// 役割:
/// - 選択した写真を円形の切り抜き枠で調整する（ピンチ拡大・ドラッグ移動）
/// - アプリ内で実際に表示される大きさ（マイページ72px・投稿48px）のプレビューを
///   切り抜き位置に連動して表示する
///
/// 入出力:
/// - 入力: [imageFile] 元画像（image_pickerで選択済み・最大1920px）
/// - 出力: トリミング済み画像を一時ファイルに書き出し `Navigator.pop(File)` で返す。
///   キャンセル（戻る）時は null を返す
class IconCropPage extends StatefulWidget {
  const IconCropPage({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<IconCropPage> createState() => _IconCropPageState();
}

class _IconCropPageState extends State<IconCropPage> {
  final CropController _cropController = CropController();

  /// 元画像のバイト列（Cropウィジェットへの入力）
  Uint8List? _imageBytes;

  /// プレビュー描画用にデコードした元画像
  ui.Image? _previewImage;

  /// 現在の切り抜き範囲（元画像のピクセル座標系）
  Rect? _cropRectInImage;

  /// Cropウィジェットが操作可能になったか
  bool _cropReady = false;

  /// 切り抜き処理の実行中か（決定ボタンの二度押し防止）
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _previewImage?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    // プレビュー用デコード（EXIF回転はFlutter側・crop_your_image側とも適用済み）
    final image = await decodeImageFromList(bytes);
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _previewImage = image;
    });
  }

  /// 切り抜きを実行し、結果を一時ファイルへ書き出して前の画面へ返す
  void _confirmCrop() {
    if (!_cropReady || _isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  Future<void> _onCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final file = await _writeTempFile(croppedImage);
          if (mounted) Navigator.pop(context, file);
        } catch (_) {
          _showCropError();
        }
      case CropFailure():
        _showCropError();
    }
  }

  /// トリミング済みバイト列を一時ディレクトリに保存する
  ///
  /// アップロード先のオブジェクト名は拡張子から決まるため（storage_service.dart）、
  /// 拡張子は実際のバイト形式（マジックバイト）に合わせる
  Future<File> _writeTempFile(Uint8List bytes) async {
    final isPng = bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final extension = isPng ? 'png' : 'jpg';
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/icon_crop_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return File(path).writeAsBytes(bytes, flush: true);
  }

  void _showCropError() {
    if (!mounted) return;
    setState(() => _isCropping = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('画像の切り抜きに失敗しました'),
        backgroundColor: AppColors.holdRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iwa,
      appBar: AppBar(
        title: Text('アイコンを調整', style: AppText.heading(size: 16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildCropArea()),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'ピンチで拡大・ドラッグで位置を調整',
                style: AppText.caption(size: 12),
              ),
            ),
            const SizedBox(height: 16),
            _buildPreviewPanel(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _cropReady && !_isCropping ? _confirmCrop : null,
                  child: _isCropping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onKabeBlue,
                          ),
                        )
                      : Text(
                          'この写真にする',
                          style: AppText.label(
                              size: 14, color: AppColors.onKabeBlue),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropArea() {
    final bytes = _imageBytes;
    if (bytes == null) {
      // 読み込み中は同色の面だけ置く（レイアウトを動かさない）
      return const ColoredBox(color: AppColors.iwa);
    }
    return Crop(
      controller: _cropController,
      image: bytes,
      aspectRatio: 1,
      withCircleUi: true,
      // 枠は固定し、画像側をドラッグ・ピンチで動かす
      interactive: true,
      fixCropRect: true,
      initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
        size: 0.85,
        aspectRatio: 1,
      ),
      baseColor: AppColors.iwa,
      maskColor: AppColors.iwa.withOpacity(0.75),
      // 枠固定のため四隅のハンドルは出さない
      cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
      progressIndicator: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.kabeBlue,
          ),
        ),
      ),
      onStatusChanged: (status) {
        final ready = status == CropStatus.ready;
        if (ready != _cropReady && mounted) {
          setState(() => _cropReady = ready);
        }
      },
      onMoved: (viewportRect, imageRect) {
        setState(() => _cropRectInImage = imageRect);
      },
      onCropped: _onCropped,
    );
  }

  /// アプリ内の実表示サイズ（マイページ72px・投稿48px）のプレビュー
  Widget _buildPreviewPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.setsuri,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.wareme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '実際の表示サイズ',
            style: AppText.caption(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPreviewCircle(size: 72, label: 'マイページ'),
              const SizedBox(width: 24),
              _buildPreviewCircle(size: 48, label: '投稿'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCircle({required double size, required String label}) {
    final image = _previewImage;
    final rect = _cropRectInImage;
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: (image != null && rect != null)
                    ? CustomPaint(
                        painter: _CropPreviewPainter(image: image, crop: rect),
                      )
                    : const ColoredBox(color: AppColors.wareme),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppText.caption(size: 11)),
      ],
    );
  }
}

/// 元画像の切り抜き範囲だけを描くプレビュー用ペインタ
class _CropPreviewPainter extends CustomPainter {
  _CropPreviewPainter({required this.image, required this.crop});

  final ui.Image image;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      crop,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_CropPreviewPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.crop != crop;
}
