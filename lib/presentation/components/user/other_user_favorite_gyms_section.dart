import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/other_user_favorite_gyms_provider.dart';
import '../gym/favorite_gym_card.dart';

/// 他ユーザーのイキタイジムセクション
///
/// 役割:
/// - 指定されたユーザーのイキタイジム一覧を表示
/// - ジムタップでジム詳細ページへ遷移
///
/// クリーンアーキテクチャにおける位置づき:
/// - Presentation層のComponent
/// - 他ユーザーのイキタイジム表示に特化したUI部品
class OtherUserFavoriteGymsSection extends ConsumerWidget {
  final String userId;

  const OtherUserFavoriteGymsSection({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteGymsAsync = ref.watch(otherUserFavoriteGymsProvider(userId));

    return favoriteGymsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'イキタイジムの取得に失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (favoriteGyms) {
        if (favoriteGyms.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'イキタイジムがまだ登録されていません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // プロバイダーを無効化して最新データを強制取得
            ref.invalidate(otherUserFavoriteGymsProvider(userId));
            
            // 新しいデータの取得完了まで待機
            await ref.read(otherUserFavoriteGymsProvider(userId).future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: favoriteGyms.length,
            itemBuilder: (context, index) {
              final gym = favoriteGyms[index];
              return FavoriteGymCard(gym: gym);
            },
          ),
        );
      },
    );
  }
}
