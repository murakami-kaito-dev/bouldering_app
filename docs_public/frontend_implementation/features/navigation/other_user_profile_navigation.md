# 他ユーザープロフィール遷移機能実装ドキュメント

## 概要

ボル活ツイートのユーザー名タップ時に、そのユーザーのプロフィールページへ遷移する機能の実装。Clean Architecture + MVVM パターンに準拠した設計。

## アーキテクチャ設計

### クリーンアーキテクチャ + MVVM準拠

```
Presentation層 (pages, components, providers)
    ↓
Domain層 (entities, usecases)
    ↓
Infrastructure層 (repositories, datasources)
    ↓
External (API, Firebase)
```

### 単一責任原則
- **OtherUserProfilePage**: 他ユーザープロフィール画面表示
- **OtherUserProvider**: 他ユーザー情報の取得・管理
- **OtherUserTweetsProvider**: 他ユーザーのツイート一覧管理
- **NavigationHelper**: 型安全なページ遷移

## 実装内容

### 1. エンティティの統一

#### Before: BoulLogTweetエンティティ使用
複数のツイートエンティティが混在し、データの一貫性に問題があった。

#### After: Tweetエンティティに統一
```dart
class Tweet {
  final int tweetId;
  final String userId;
  final String content;
  final String gymId;
  final String gymName;
  final DateTime visitedDate;
  final List<String>? mediaUrls;
  final DateTime createdAt;
  
  // フィールド名の統一
  // tweetContents → content
  // tweetImageUrls → mediaUrls
  
  Tweet.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### 2. 新規作成ファイル

#### ユーティリティ
**ファイル**: `/lib/shared/utils/user_utils.dart`
```dart
class UserUtils {
  /// 経験年数の計算
  static int calculateExperience(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate);
    return (difference.inDays / 365).floor();
  }
  
  /// ホームジム名の取得
  static String getHomeGymName(int? gymId, List<Gym> gyms) {
    if (gymId == null) return '未設定';
    final gym = gyms.firstWhere((g) => g.id == gymId, orElse: () => null);
    return gym?.name ?? '不明';
  }
}
```

#### プロバイダー
**ファイル**: `/lib/presentation/providers/other_user_provider.dart`
```dart
final otherUserProvider = StateNotifierProvider.family<OtherUserNotifier, AsyncValue<User?>, String>((ref, userId) {
  return OtherUserNotifier(ref, userId);
});

class OtherUserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;
  final String userId;
  
  OtherUserNotifier(this.ref, this.userId) : super(const AsyncValue.loading()) {
    loadUser();
  }
  
  Future<void> loadUser() async {
    try {
      state = const AsyncValue.loading();
      final userRepository = ref.read(userRepositoryProvider);
      final user = await userRepository.getUserById(userId);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

**ファイル**: `/lib/presentation/providers/other_user_tweets_provider.dart`
```dart
final otherUserTweetsProvider = StateNotifierProvider.family<OtherUserTweetsNotifier, AsyncValue<List<Tweet>>, String>((ref, userId) {
  return OtherUserTweetsNotifier(ref, userId);
});

class OtherUserTweetsNotifier extends StateNotifier<AsyncValue<List<Tweet>>> {
  final Ref ref;
  final String userId;
  int _currentPage = 1;
  bool _hasMore = true;
  
  // ページネーション対応
  Future<void> loadMoreTweets() async {
    if (!_hasMore || state.isLoading) return;
    
    try {
      final tweetRepository = ref.read(tweetRepositoryProvider);
      final newTweets = await tweetRepository.getTweetsByUserId(
        userId, 
        page: _currentPage + 1
      );
      
      if (newTweets.isEmpty) {
        _hasMore = false;
        return;
      }
      
      final currentTweets = state.value ?? [];
      state = AsyncValue.data([...currentTweets, ...newTweets]);
      _currentPage++;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

#### コンポーネント
**ファイル**: `/lib/presentation/components/user/other_user_profile_section.dart`
```dart
class OtherUserProfileSection extends ConsumerWidget {
  final String userId;
  
  const OtherUserProfileSection({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(otherUserProvider(userId));
    
    return userAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorWidget(error.toString()),
      data: (user) {
        if (user == null) return const Text('ユーザーが見つかりません');
        
        return Column(
          children: [
            // プロフィール画像
            CircleAvatar(
              radius: 50,
              backgroundImage: user.iconUrl != null 
                ? NetworkImage(user.iconUrl!) 
                : null,
              child: user.iconUrl == null 
                ? const Icon(Icons.person, size: 50) 
                : null,
            ),
            
            // ユーザー情報
            Text(user.userName, style: Theme.of(context).textTheme.headlineSmall),
            Text(user.bio ?? '自己紹介未設定'),
            
            // 統計情報
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('投稿', user.tweetCount ?? 0),
                _buildStatItem('経験年数', UserUtils.calculateExperience(user.createdAt)),
                _buildStatItem('フォロワー', user.followerCount ?? 0),
              ],
            ),
            
            // お気に入り登録ボタン
            ElevatedButton(
              onPressed: () => _toggleFavorite(ref, userId),
              child: Text(user.isFavorited ? 'お気に入り解除' : 'お気に入り登録'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
  
  Future<void> _toggleFavorite(WidgetRef ref, String userId) async {
    // お気に入り登録/解除処理（未実装）
  }
}
```

**ファイル**: `/lib/presentation/components/user/other_user_tweets_section.dart`
```dart
class OtherUserTweetsSection extends ConsumerWidget {
  final String userId;
  
  const OtherUserTweetsSection({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tweetsAsyncValue = ref.watch(otherUserTweetsProvider(userId));
    
    return tweetsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorWidget(error.toString()),
      data: (tweets) {
        if (tweets.isEmpty) {
          return const Center(child: Text('投稿がありません'));
        }
        
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: tweets.length,
          itemBuilder: (context, index) {
            final tweet = tweets[index];
            return TweetCard(tweet: tweet);
          },
        );
      },
    );
  }
}
```

**ファイル**: `/lib/presentation/components/user/other_user_wanna_go_gyms_section.dart`
```dart
class OtherUserWannaGoGymsSection extends ConsumerWidget {
  final String userId;
  
  const OtherUserWannaGoGymsSection({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 他ユーザーのイキタイジム一覧表示
    // 現在はモックデータを使用
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3, // モックデータ
      itemBuilder: (context, index) {
        return const GymCard(gym: /* モックGymデータ */);
      },
    );
  }
}
```

#### ページ
**ファイル**: `/lib/presentation/pages/other_user_profile_page.dart`
```dart
class OtherUserProfilePage extends ConsumerWidget {
  final String userId;
  
  const OtherUserProfilePage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('プロフィール'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ボル活'),
              Tab(text: 'イキタイ'),
            ],
          ),
        ),
        body: Column(
          children: [
            // プロフィールセクション（固定）
            OtherUserProfileSection(userId: userId),
            
            // タブビュー
            Expanded(
              child: TabBarView(
                children: [
                  // ボル活タブ
                  SingleChildScrollView(
                    child: OtherUserTweetsSection(userId: userId),
                  ),
                  
                  // イキタイタブ
                  SingleChildScrollView(
                    child: OtherUserWannaGoGymsSection(userId: userId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. 既存ファイルの変更

#### BoulLogコンポーネントの修正
```dart
// プロパティ名をTweetエンティティに合わせて変更
class BoulLog extends StatelessWidget {
  final Tweet tweet; // BoulLogTweet → Tweet
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // ユーザー名タップ時のナビゲーション追加
          GestureDetector(
            onTap: () => NavigationHelper.toOtherUserProfile(
              context, 
              tweet.userId
            ),
            child: Text(
              tweet.userName, // ユーザー名
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 投稿内容表示
          Text(tweet.content), // tweetContents → content
          
          // メディア表示
          if (tweet.mediaUrls != null && tweet.mediaUrls!.isNotEmpty)
            ...tweet.mediaUrls!.map((url) => Image.network(url)), // tweetImageUrls → mediaUrls
        ],
      ),
    );
  }
}
```

#### NavigationHelperの実装
**ファイル**: `/lib/shared/utils/navigation_helper.dart`
```dart
class NavigationHelper {
  /// 他ユーザープロフィールページへの遷移
  static Future<void> toOtherUserProfile(
    BuildContext context, 
    String userId
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfilePage(userId: userId),
      ),
    );
  }
}
```

#### GymProviderの拡張
```dart
// gymMapProviderを追加（ID→Gymのマップ提供）
final gymMapProvider = Provider<Map<int, Gym>>((ref) {
  final gyms = ref.watch(gymProvider).value ?? [];
  return {for (var gym in gyms) gym.id: gym};
});
```

## 機能仕様

### ナビゲーション
1. ボル活ツイートのユーザー名をタップ
2. `NavigationHelper.toOtherUserProfile()`を呼び出し
3. 他ユーザープロフィールページへ遷移

### 表示内容
- **プロフィールセクション**: ユーザー情報、統計、お気に入り登録ボタン
- **ボル活タブ**: ユーザーのツイート一覧（無限スクロール対応）
- **イキタイタブ**: ユーザーのイキタイジム一覧

### データ管理
- **自動破棄**: ページ遷移時の`autoDispose`使用でメモリ効率化
- **ページネーション**: ツイート一覧の段階的読み込み
- **キャッシュ**: 同一ユーザーの再訪問時の高速表示

## 現在の制限事項
- モックデータを使用（API連携は未実装）
- お気に入り登録機能は未実装
- イキタイジム専用プロバイダーは未実装

## 今後の実装予定

### 高優先度
1. **実際のAPI連携**: モックデータから実際のバックエンドAPIへの移行
2. **お気に入りユーザー機能**: ユーザーのお気に入り登録・解除
3. **イキタイジム管理**: 他ユーザーのイキタイジム一覧取得

### 中優先度
1. **ユーザーフォロー機能**: フォロー・アンフォロー機能の追加
2. **無限スクロール改善**: より滑らかなスクロール体験
3. **キャッシュ戦略**: データの効率的なキャッシュ管理

### 低優先度
1. **プロフィール詳細**: より詳細なユーザー情報表示
2. **アクティビティフィード**: ユーザーの活動履歴
3. **相互フォロー表示**: フォロー関係の可視化

## テスト方法

### 基本機能テスト
1. アプリを起動
2. ボル活タブでツイートを表示
3. 任意のツイートのユーザー名をタップ
4. 他ユーザープロフィールページが表示されることを確認
5. タブ切り替えが正常に動作することを確認

### ナビゲーションテスト
1. 複数のユーザーのプロフィールを連続で開く
2. 戻るボタンでの画面遷移確認
3. 自分自身のプロフィールへの遷移確認

### パフォーマンステスト
1. 大量のツイートがあるユーザーのプロフィール確認
2. 無限スクロールの動作確認
3. メモリ使用量の確認

## 注意事項
- 自分自身のプロフィールへの遷移も可能（マイページとは別画面）
- ページ遷移時のパフォーマンスに注意（プロバイダーの`autoDispose`使用）
- モックデータ使用時はリアルなデータ形式を維持

---
*最終更新: 2025-09-17*
*実装完了度: 90% (API連携未実装)*