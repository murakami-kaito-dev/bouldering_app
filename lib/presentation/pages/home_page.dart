import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';
import '../../shared/constants/app_routes.dart';
import '../components/common/pressable.dart';

/// ホーム画面（ジム検索の起点）
///
/// 構成（岩と粉 Phase 2b）:
/// - 最上部: 小さなロゴ行（アイコン+アプリ名）。画面の主役は検索なので控えめに
/// - 主役: 条件検索の大きなピル
/// - 地図: プレビュー画像を敷いた没入カード（カード全体がタップ領域）
/// - 写真募集: 静かな1行リンクに格下げ（以前の絵文字バナーは廃止）
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// ロゴ（表示 34px。デコードは 3x 相当の 102px に縮小して軽くする）
  ///
  /// AppRoot がスプラッシュ中にこのプロバイダで precache するので、ホームの最初の
  /// フレームから同期的に描ける（Issue #60 の続き: 起動直後のアセット遅延描画対策）。
  /// 画面側と precache 側で同じプロバイダを使うこと（ImageCache のキーが一致する条件）
  static const ImageProvider logoImage =
      ResizeImage(AssetImage('assets/icon.png'), width: 102);

  /// 地図カードのプレビュー画像（同上）
  static const ImageProvider mapImage =
      AssetImage('lib/view/assets/map_image.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ロゴ行（小さく・左上）
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: const Image(
                      image: logoImage,
                      width: 34,
                      height: 34,
                      gaplessPlayback: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('イワノボリタイ', style: AppText.display(size: 17)),
                ],
              ),

              const SizedBox(height: 28),

              // 画面の見出し
              Text('ジムをさがす', style: AppText.display(size: 26)),
              const SizedBox(height: 16),

              // 主役: 条件検索
              Pressable(
                  child: Material(
                color: AppColors.setsuri,
                shape: const StadiumBorder(
                  side: BorderSide(color: AppColors.wareme),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.gymSearch),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            size: 26, color: AppColors.chalk),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('条件からジムをさがす',
                                  style: AppText.body(
                                      size: 15, weight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('エリア・種目・料金で絞り込み',
                                  style: AppText.caption(size: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 14),

              // 地図検索: 没入プレビューカード（全体がタップ領域）
              Pressable(
                  child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Stack(
                  children: [
                    // 地図プレビュー
                    const Image(
                      image: mapImage,
                      width: double.infinity,
                      height: 170,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                    // 下部スクリム（文字の可読性確保）
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.72),
                            ],
                            stops: const [0.35, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // ラベル
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('地図からさがす',
                                    style: AppText.heading(size: 17)),
                                const SizedBox(height: 2),
                                Text('現在地の近くのジムを表示します',
                                    style: AppText.caption(
                                        size: 11, color: AppColors.chalk)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward,
                              size: 20, color: AppColors.chalk),
                        ],
                      ),
                    ),
                    // タップ領域（カード全体）
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.gymMap),
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 32),

              // 写真募集: 静かな1行リンク
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final Uri formUrl =
                      Uri.parse('https://forms.gle/oMGHSeEtHs8HAPkc9');
                  if (await canLaunchUrl(formUrl)) {
                    await launchUrl(formUrl,
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_camera_outlined,
                          size: 18, color: AppColors.sunabokori),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('ジムの写真を募集しています',
                            style: AppText.caption(size: 13)),
                      ),
                      Text('フォームで送る',
                          style: AppText.caption(
                              size: 13, color: AppColors.kabeBlue)),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.kabeBlue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
