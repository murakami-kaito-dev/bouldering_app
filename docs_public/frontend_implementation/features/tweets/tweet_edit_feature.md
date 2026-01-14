# ツイート編集機能実装ドキュメント

## 概要

ボル活（ツイート）の編集機能の実装。ユーザーが自分の投稿した内容を後から修正できる機能。Clean Architecture + MVVM パターンに準拠した設計。

## アーキテクチャ設計

### クリーンアーキテクチャ準拠

```
Presentation層 (activity_post_page.dart)
    ↓
Domain層 (activity_post_usecases.dart)
    ↓
Domain層 (tweet_repository.dart - interface)
    ↓
Infrastructure層 (tweet_repository_impl.dart)
    ↓
Infrastructure層 (tweet_datasource.dart)
    ↓
External (API Client)
```

### MVVM パターン
- **View**: ActivityPostPage（投稿・編集UI表示）
- **ViewModel**: ActivityPostUseCase（ビジネスロジック）
- **Model**: Tweetエンティティ（データ表現）

### 単一責任原則
- **ActivityPostPage**: 投稿・編集UI表示
- **ActivityPostUseCase**: 投稿・編集ビジネスロジック
- **TweetRepository**: ツイートCRUD操作
- **TweetDataSource**: APIとの通信

## 設計方針

### 新規投稿と編集機能の統合
新規投稿と編集機能を一つのファイル（`activity_post_page.dart`）にまとめる方針を採用。

#### 統合の理由
1. **UIの共通性が高い**: 入力フォーム、画像選択、ジム選択などのUIコンポーネントがほぼ同一
2. **ロジックの再利用性**: バリデーション、画像処理、投稿処理など共通ロジックが多い
3. **モード切替の簡潔性**: `isEditMode`フラグで条件分岐
4. **保守性**: 機能追加時に両方のモードに同時に反映

## 実装内容

### 1. 編集ボタンからの遷移

#### boul_log.dart の修正
```dart
// 編集ページへ遷移
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ActivityPostPage(
      initialData: {
        'tweetId': widget.tweetId,
        'tweetContents': widget.content,
        'gymId': widget.gymId.toString(),
        'gymName': widget.gymName,
        'visitedDate': widget.visitedDate,
        'mediaUrls': widget.mediaUrls ?? [],
      },
    ),
  ),
);
```

### 2. 編集モード対応

#### activity_post_page.dart の改善点

**タイトル表示の改善**
```dart
AppBar(
  title: Text(
    isEditMode ? 'ボル活編集' : 'ボル活投稿',
    style: const TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

**ボタンテキストの改善**
```dart
ElevatedButton(
  onPressed: _onSubmit,
  child: Text(
    isEditMode ? '更新する' : '投稿する',
    style: const TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

**編集時のジム選択無効化**
```dart
TextField(
  readOnly: true,
  enabled: !isEditMode,  // 編集時は無効
  decoration: InputDecoration(
    hintText: selectedGym ?? "ジムを選択してください",
    suffixIcon: isEditMode 
      ? const Icon(Icons.lock, color: Colors.grey) 
      : const Icon(Icons.search),
    border: const OutlineInputBorder(),
  ),
)
```

### 3. バックエンドPUT処理の実装

#### Domain層: tweet_repository.dart
```dart
abstract class TweetRepository {
  Future<bool> updateTweet({
    required int tweetId,
    required String userId,
    required int gymId,
    required String content,
    required DateTime visitedDate,
    String? movieUrl,
    List<String>? mediaUrls,
  });
}
```

#### Infrastructure層: tweet_repository_impl.dart
```dart
@override
Future<bool> updateTweet({
  required int tweetId,
  required String userId,
  required int gymId,
  required String content,
  required DateTime visitedDate,
  String? movieUrl,
  List<String>? mediaUrls,
}) async {
  // バリデーション
  if (tweetId <= 0) {
    throw ArgumentError('ツイートIDは正の整数で指定してください');
  }
  
  // セキュリティ: 投稿者確認
  final tweet = await _dataSource.getTweetById(tweetId);
  if (tweet?.userId != userId) {
    throw ArgumentError('自分の投稿のみ更新可能です');
  }
  
  // データソースを通じて更新実行
  return await _dataSource.updateTweet(
    tweetId: tweetId,
    userId: userId,
    gymId: gymId,
    content: content,
    visitedDate: visitedDate,
    movieUrl: movieUrl,
    mediaUrls: mediaUrls,
  );
}
```

#### Infrastructure層: tweet_datasource.dart
```dart
Future<bool> updateTweet({
  required int tweetId,
  required String userId,
  required int gymId,
  required String content,
  required DateTime visitedDate,
  String? movieUrl,
  List<String>? mediaUrls,
}) async {
  final formattedDate = DateFormat('yyyy-MM-dd').format(visitedDate);
  
  final response = await _apiClient.get(
    requestId: 11,  // ツイート更新API
    parameters: {
      'tweet_id': tweetId.toString(),
      'user_id': userId,
      'gym_id': gymId.toString(),
      'tweet_contents': content,
      'visited_date': formattedDate,
      'movie_url': movieUrl ?? '',
      'media_urls': mediaUrls?.join(',') ?? '',
    },
  );
  
  return response.isNotEmpty;
}
```

#### Domain層: activity_post_usecases.dart
```dart
Future<bool> updateActivity({
  required int tweetId,
  required String userId,
  required int gymId,
  required String tweetContents,
  required DateTime visitedDate,
  List<File>? mediaFiles,
  List<String>? existingUrls,
  List<String>? originalUrls,
  String? movieUrl,
}) async {
  try {
    // 削除するメディアURLを特定
    final urlsToDelete = originalUrls?.where((url) => 
      !(existingUrls?.contains(url) ?? false)
    ).toList() ?? [];
    
    // 削除処理を実行
    for (final url in urlsToDelete) {
      try {
        await _storageRepository.deleteMedia(url);
        print('[UPDATE_ACTIVITY] メディア削除完了: $url');
      } catch (e) {
        print('[UPDATE_ACTIVITY] メディア削除エラー: $url, エラー: $e');
      }
    }
    
    // 新規画像をアップロード
    List<String> newUploadedUrls = [];
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      newUploadedUrls = await _storageRepository.uploadMultiplePostMedia(
        mediaFiles, 
        'photo'
      );
    }
    
    // 既存URLと新規URLを結合
    final allMediaUrls = [
      ...(existingUrls ?? []),
      ...newUploadedUrls,
    ];
    
    // リポジトリを通じて更新処理を実行
    return await _repository.updateTweet(
      tweetId: tweetId,
      userId: userId,
      gymId: gymId,
      content: tweetContents,
      visitedDate: visitedDate,
      movieUrl: movieUrl,
      mediaUrls: allMediaUrls,
    );
  } catch (e) {
    print('[UPDATE_ACTIVITY] エラー: $e');
    rethrow;
  }
}
```

## セキュリティ要件

### 認証・認可
1. **投稿者確認**: 編集・削除は投稿者本人のみ可能
2. **ツイートID検証**: 存在しないツイートの編集を防止
3. **ユーザーID検証**: 空文字・不正なIDをチェック

### バリデーション
1. **文字数制限**: ツイート内容は1文字以上500文字以下
2. **日付検証**: 訪問日は現在日以前
3. **メディア制限**: 画像は最大5枚まで
4. **ファイル形式**: 動画とメディアファイルの同時投稿を防止

### セキュリティチェック例
```dart
// 投稿者確認
final currentTweet = await tweetRepository.getTweetById(tweetId);
if (currentTweet?.userId != currentUserId) {
  throw UnauthorizedException('自分の投稿のみ編集可能です');
}

// 内容バリデーション
if (content.isEmpty || content.length > 500) {
  throw ValidationException('投稿内容は1文字以上500文字以下で入力してください');
}

// 日付バリデーション
if (visitedDate.isAfter(DateTime.now())) {
  throw ValidationException('訪問日は現在日以前で設定してください');
}
```

## API仕様

### ツイート更新API
- **Request ID**: 11
- **Method**: GET（現在の仕様に合わせて）
- **Parameters**:
  - `tweet_id`: 更新対象のツイートID
  - `user_id`: 更新実行者のユーザーID
  - `gym_id`: ジムID
  - `tweet_contents`: ツイート内容
  - `visited_date`: 訪問日（YYYY-MM-DD形式）
  - `movie_url`: 動画URL（オプション）
  - `media_urls`: メディアURLリスト（カンマ区切り）

### レスポンス
- **成功**: 空でないレスポンス
- **失敗**: 空のレスポンスまたは例外

## 使用方法

### 編集フロー
1. **編集開始**: ボル活カードの「⋮」→「編集する」をタップ
2. **編集画面**: 既存データが表示された編集画面が開く
3. **内容変更**: テキスト、日付、画像を編集
4. **更新実行**: 「更新する」ボタンをタップ
5. **完了**: 成功メッセージ表示後、前画面に戻る

### 編集制限
- **ジム変更不可**: 編集時はジム選択を無効化
- **投稿者のみ**: 自分の投稿のみ編集可能
- **リアルタイム保存**: 変更内容の自動保存なし

## メディア管理

### 画像の追加・削除
```dart
// 既存画像の削除処理
final urlsToDelete = originalUrls.where((url) => 
  !existingUrls.contains(url)
).toList();

for (final url in urlsToDelete) {
  await storageRepository.deleteMedia(url);
}

// 新規画像のアップロード
final newUrls = await storageRepository.uploadMultiplePostMedia(
  newImageFiles, 
  'photo'
);

// 最終的なメディアURL配列
final finalMediaUrls = [...existingUrls, ...newUrls];
```

### メディア最適化
- **圧縮**: アップロード前の画像圧縮
- **形式統一**: JPEG形式での統一
- **サイズ制限**: 1ファイル最大10MB

## 今後の改善点

### 機能拡張
1. **楽観的ロック**: 同時編集の競合対策
2. **履歴管理**: 編集履歴の保存・表示
3. **差分更新**: 変更された項目のみAPI送信
4. **オフライン対応**: ネットワーク未接続時の編集保存

### UI/UX改善
1. **プレビュー機能**: 編集内容のリアルタイムプレビュー
2. **下書き保存**: 一時保存機能
3. **変更警告**: 未保存の変更がある場合の警告
4. **操作ガイド**: 編集方法のヘルプ表示

## テスト方法

### 正常系テスト
1. 自分の投稿の編集ボタンが表示されることを確認
2. 編集画面で既存データが正しく表示されることを確認
3. テキスト・日付・画像を変更して更新が成功することを確認
4. 更新後のデータが正しく反映されることを確認

### 異常系テスト
1. 他人の投稿では編集ボタンが表示されないことを確認
2. 不正なデータでの更新が失敗することを確認
3. ネットワークエラー時に適切なエラーメッセージが表示されることを確認
4. バリデーションエラーの適切な表示確認

### セキュリティテスト
1. 他人のツイートIDでの編集試行（認可エラー確認）
2. 不正なパラメータでのAPI呼び出し確認
3. SQL インジェクション対策の確認

---
*最終更新: 2025-09-17*
*実装完了度: 100%*