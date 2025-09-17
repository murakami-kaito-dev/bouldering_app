import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/dependency_injection.dart';
import 'gym/favorite_gym_card.dart';
import '../../domain/entities/gym.dart';

// Mock実装（テスト時のみ使用）
// import '../../shared/data/mock_data.dart';

/// イキタイジムセクション
///
/// 役割:
/// - 自分が登録したイキタイジムを表示するクラス
/// - 過去のプロジェクトと同様の表示形式
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のComponent
/// - お気に入りジムデータ表示に特化したUI部品
class FavoriteGymsSection extends ConsumerStatefulWidget {
  const FavoriteGymsSection({super.key});

  @override
  FavoriteGymsSectionState createState() => FavoriteGymsSectionState();
}

class FavoriteGymsSectionState extends ConsumerState<FavoriteGymsSection> {
  // ■ プロパティ
  final ScrollController _scrollController = ScrollController();
  List<Gym> _favoriteGyms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 起動時に一度だけお気に入りジムを取得する
    Future.microtask(() async {
      await _loadFavoriteGyms();
    });
  }

  /// ■ dispose
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// お気に入りジムを読み込む
  Future<void> _loadFavoriteGyms() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final getUserFavoriteGymsUseCase = ref.read(getUserFavoriteGymsUseCaseProvider);
      final gymDataList = await getUserFavoriteGymsUseCase.execute(currentUser.id);
      
      final gyms = gymDataList.map((data) => Gym.fromJson(data)).toList();
      
      if (mounted) {
        setState(() {
          _favoriteGyms = gyms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ■ メソッド
  /// イキタイジムを再取得する
  Future<void> _refreshFavoriteGyms() async {
    await _loadFavoriteGyms();
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshFavoriteGyms,
      child: _favoriteGyms.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              children: const [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 64),
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'まだイキタイジムがありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ジム詳細ページで「イキタイ」ボタンを押して登録してください',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              key: const PageStorageKey<String>('favorite_gyms_section'),
              itemCount: _favoriteGyms.length,
              itemBuilder: (context, index) {
                final gym = _favoriteGyms[index];
                return FavoriteGymCard(gym: gym);
              },
            ),
    );
  }
}
