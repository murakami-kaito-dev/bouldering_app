import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/common/app_logo.dart';
import '../theme/app_tokens.dart';
import '../../shared/constants/app_routes.dart';

/// ホーム画面
/// 
/// 役割:
/// - アプリのメイン画面として機能
/// - ジム検索の起点となる
/// - アプリの主要機能へのナビゲーション
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // ロゴ
                const AppLogo(),
                const SizedBox(height: 48),

                // ジム条件検索
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.gymSearch);
                  },
                  borderRadius: BorderRadius.circular(32),
                  splashColor: AppColors.sunabokori.withOpacity(0.3),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: ShapeDecoration(
                      color: AppColors.setsuri,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: AppColors.wareme),
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, size: 32.0, color: AppColors.kabeBlue),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '条件からジムを探す',
                                style: TextStyle(
                                  color: AppColors.chalk,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'ボルダリング以外の種目も検索できます',
                                  style: TextStyle(
                                    color: AppColors.sunabokori,
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // 地図検索ウィジェット
                Container(
                  width: double.infinity,
                  height: 136,
                  decoration: ShapeDecoration(
                    image: const DecorationImage(
                      image: AssetImage("lib/view/assets/map_image.png"),
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.gymMap);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: ShapeDecoration(
                          color: AppColors.kabeBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '地図からジムを探す',
                          style: TextStyle(
                            color: AppColors.onKabeBlue,
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 52),

                /// 写真提供URL実装
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.wareme,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '🙇‍♂️ 現在、ジム写真を募集中です！🙇‍♀️',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.chalk,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ジムの写真を提供してくれる方は ぜひご協力ください！',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.chalk,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Googleフォームへのリンクを外部ブラウザで開く
                            final Uri formUrl = Uri.parse(
                                'https://forms.gle/oMGHSeEtHs8HAPkc9');
                            if (await canLaunchUrl(formUrl)) {
                              await launchUrl(formUrl,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              // URL起動に失敗した場合は何もしない（エラーハンドリングは上位で行う）
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('ジムの写真を送る'),
                              SizedBox(height: 2),
                              Text(
                                '(Googleフォーム)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kabeBlue,
                            foregroundColor: AppColors.onKabeBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}