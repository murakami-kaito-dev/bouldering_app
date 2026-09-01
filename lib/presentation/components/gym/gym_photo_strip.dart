import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/gym_photo.dart';
import '../../providers/gym_photos_provider.dart';
import '../common/image_viewer.dart';
import '../../theme/app_tokens.dart';

/// ジム写真の横スクロール表示（一覧カード・地図カード・詳細画面で共用）
///
/// 役割:
/// - gymPhotosProvider(gymId) を watch して写真を表示する
/// - 写真の出どころが Google（Places API）の場合、規約で必須の帰属表示を写真上に重ねる
/// - 写真なし・読み込み中はプレースホルダーを表示する
/// - [enableViewer] を有効にすると、タップでツイート写真と同じ拡大ビューア
///   （ImageViewer: ピンチズーム・スワイプ送り・Hero遷移）を開く
class GymPhotoStrip extends ConsumerWidget {
  const GymPhotoStrip({
    super.key,
    required this.gymId,
    this.height = 100,
    this.photoWidth = 132,
    this.maxPhotos = 5,
    this.enableViewer = false,
    this.heroTagPrefix,
  });

  final int gymId;
  final double height;
  final double photoWidth;
  final int maxPhotos;

  /// タップで拡大表示を開くか（ジム詳細で使用。カード類はカード自体のタップと競合するため無効）
  final bool enableViewer;

  /// Hero遷移用タグの接頭辞（enableViewer時に使用。画面内で一意にすること）
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(gymPhotosProvider(gymId));

    return SizedBox(
      height: height,
      child: photosAsync.when(
        loading: () => _placeholder(label: null, showSpinner: true),
        error: (_, __) => _placeholder(label: '写真なし'),
        data: (set) {
          if (set.isEmpty) return _placeholder(label: '写真なし');
          final photos = set.photos.take(maxPhotos).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, i) {
              Widget photo = _buildPhoto(set, photos[i]);

              // タップで拡大表示（ツイート写真と同じImageViewer。ピンチズーム・スワイプ送り対応）
              if (enableViewer) {
                final prefix = heroTagPrefix ?? 'gym_photo_$gymId';
                photo = GestureDetector(
                  onTap: () => ImageViewer.show(
                    context: context,
                    imageUrls: photos.map((p) => p.url).toList(),
                    initialIndex: i,
                    heroTagPrefix: prefix,
                  ),
                  child: Hero(tag: '${prefix}_$i', child: photo),
                );
              }

              return Padding(
                padding:
                    EdgeInsets.only(right: i != photos.length - 1 ? 8.0 : 0.0),
                child: photo,
              );
            },
          );
        },
      ),
    );
  }

  /// 写真1枚分（角丸+Google帰属バッジ）
  Widget _buildPhoto(GymPhotoSet set, GymPhoto photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: photo.url,
            width: photoWidth,
            height: height,
            fit: BoxFit.cover,
            // 表示サイズ相当で縮小デコードし、メモリキャッシュに乗せ続ける
            // （原寸デコードによるキャッシュ追い出し=毎回ローディングを防ぐ）
            memCacheWidth: 400,
            placeholder: (context, url) => Container(
              width: photoWidth,
              height: height,
              color: AppColors.wareme,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              width: photoWidth,
              height: height,
              color: AppColors.wareme,
              child: const Icon(Icons.broken_image, color: AppColors.sunabokori),
            ),
          ),
          // Google写真の帰属表示（Places API規約で必須）
          if (set.isFromGoogle)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Google',
                  style: TextStyle(color: AppColors.chalk, fontSize: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder({String? label, bool showSpinner = false}) {
    return Row(
      children: [
        Container(
          width: photoWidth,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.wareme,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: showSpinner
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(label ?? '',
                    style: TextStyle(color: AppColors.sunabokori, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
