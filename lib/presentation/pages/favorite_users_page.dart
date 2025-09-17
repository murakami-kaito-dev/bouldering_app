import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../components/user/favorite_user_card.dart';
import '../providers/favorite_users_list_provider.dart';
import '../providers/favorite_user_provider.dart';

/// お気に入りユーザー一覧ページ
/// 
/// 役割:
/// - お気に入り登録しているユーザー一覧表示
/// - お気に入り登録・解除機能
/// - ユーザープロフィールへの遷移
/// - 他ユーザー画面から戻った時の状態同期
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のPage
/// - お気に入りユーザー管理機能のメイン画面
class FavoriteUsersPage extends ConsumerStatefulWidget {
  const FavoriteUsersPage({super.key});

  @override
  ConsumerState<FavoriteUsersPage> createState() => _FavoriteUsersPageState();
}

class _FavoriteUsersPageState extends ConsumerState<FavoriteUsersPage> 
    with RouteAware {
  @override
  void initState() {
    super.initState();
    
    // お気に入りユーザー一覧を読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoriteUsersListProvider.notifier).loadFavoriteUsers();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 他ユーザー画面から戻ってきた時に呼ばれる
  @override 
  void didPopNext() {
    // お気に入り状態の同期（リスト自体は再取得しない）
    ref.read(favoriteUsersListProvider.notifier).syncFavoriteStatus();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteUsersState = ref.watch(favoriteUsersListProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF7FF),
        surfaceTintColor: const Color(0xFFFEF7FF),
        title: const Text(
          'お気に入り',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(favoriteUsersListProvider.notifier).refresh();
        },
        child: favoriteUsersState.when(
          data: (users) => _buildUsersList(users),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return FavoriteUserCard(
          user: user,
          onFavoriteToggle: () async {
            final success = await ref
                .read(favoriteUsersListProvider.notifier)
                .toggleFavorite(user.id);
            
            if (!mounted) return;
            
            if (success) {
              // favorite_user_providerの状態も更新
              await ref.read(favoriteUserProvider.notifier).refresh();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ref.read(isFavoriteUserProvider(user.id))
                        ? 'お気に入りに登録しました'
                        : 'お気に入りを解除しました',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('エラーが発生しました'),
                ),
              );
            }
          },
          onAfterNavigation: () {
            // 他ユーザー画面から戻ってきた時の処理
            ref.read(favoriteUsersListProvider.notifier).syncFavoriteStatus();
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'お気に入りユーザーがいません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ユーザーをお気に入り登録すると\nここに表示されます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(favoriteUsersListProvider.notifier).refresh();
              },
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteObserverの設定（他画面から戻った時の処理用）
    // 必要に応じて実装
  }
}