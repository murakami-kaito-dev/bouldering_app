# アカウント削除機能実装ドキュメント

## 概要

設定ページからのアカウント削除（退会）機能を実装。Firebase AuthenticationとCloud SQLの両方からユーザーデータを完全削除する機能です。

## アーキテクチャ設計

### クリーンアーキテクチャ + MVVM準拠

```
Presentation層 (settings_page.dart)
    ↓
Domain層 (auth_usecases.dart)
    ↓
Infrastructure層 (firebase_auth_service.dart, user_repository_impl.dart)
    ↓
External (Firebase Auth, Cloud SQL API)
```

### 単一責任原則
- **SettingsPage**: アカウント削除UI表示とユーザー入力
- **AuthNotifier**: 認証関連ビジネスロジック
- **UserProvider**: ユーザーデータ管理

## 実装内容

### 1. UI実装（settings_page.dart）

#### 削除確認フロー
```dart
// 1. 最終確認ダイアログ
void _confirmAccountDeletion(BuildContext context, WidgetRef ref) {
  // 削除内容の明示、取り消し不可能な旨を強調
}

// 2. パスワード入力ダイアログ  
void _showPasswordDialog(BuildContext context, WidgetRef ref) {
  // セキュリティ目的の説明、表示/非表示切り替え、Enterキー対応
}

// 3. 削除処理実行
Future<void> _executeAccountDeletion(...) async {
  // ローディング表示、エラーハンドリング
}
```

#### UX改善点
- パスワード入力時の表示/非表示切り替えボタン
- Enterキーでの削除実行対応
- ローディング表示によるフィードバック
- 分かりやすいエラーメッセージ表示

### 2. 認証ロジック（auth_provider.dart）

#### セキュリティ要件準拠
```dart
Future<void> deleteAccount({required String password}) async {
  try {
    // 1. パスワードによる再認証（Firebase要件）
    await currentUser.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      ),
    );
    
    // 2. Firebase Authからユーザー削除
    await currentUser.delete();
    
    // 3. Cloud SQLからユーザー情報削除
    await ref.read(userProvider.notifier).deleteUser(userId);
    
    // 4. ローカル状態クリア
    state = false;
  } catch (e) {
    // 適切なエラーハンドリング
  }
}
```

### 3. バックエンド実装（userService.ts）

#### データ削除順序（外部キー制約対応）
```typescript
// トランザクション内で実行
1. tweet_media（ツイートのメディアファイル）
2. tweets（ユーザーの投稿）
3. user_favorites（ユーザー間のお気に入り関係）
4. gym_favorites（ユーザーのお気に入りジム）
5. users（ユーザー本体）
```

#### テーブル名修正
- `favorite_user_relations` → `user_favorites`
- `favorite_gyms` → `gym_favorites`

## セキュリティ設計

### Firebase Authセキュリティ
- **再認証必須**: アカウント削除前にパスワード再入力を義務化
- **エラーハンドリング**: 
  - `wrong-password`: パスワード間違い
  - `too-many-requests`: 試行回数制限
  - その他のFirebase例外の適切な処理

### データ削除の完全性
- **カスケード削除**: ユーザーに関連するすべてのデータを削除
- **処理順序の重要性**: Firebase Auth削除 → Cloud SQL削除の順序
- **部分失敗への対応**: Firebase削除成功時はローカル状態をクリア

## 動作フロー

1. **設定ページ**: 「アカウントを削除」ボタンをタップ
2. **最終確認**: 削除内容確認 → 「削除を実行」
3. **パスワード入力**: 本人確認のためパスワード再入力
4. **削除処理**: 
   - ローディング表示
   - Firebase Auth再認証
   - Firebase Authユーザー削除
   - Cloud SQLユーザー削除
5. **完了**: 成功メッセージ表示 → 未ログインページへ自動遷移

## 実装ファイル

### フロントエンド
- `/lib/presentation/pages/settings_page.dart`
- `/lib/presentation/providers/auth_provider.dart`
- `/lib/presentation/providers/user_provider.dart`

### バックエンド
- `/backend/src/services/userService.ts`
- `/backend/src/routes/users.ts`

### ドメイン/インフラ層
- `/lib/domain/usecases/user_usecases.dart`
- `/lib/infrastructure/repositories/user_repository_impl.dart`
- `/lib/infrastructure/datasources/user_datasource.dart`

## テスト観点

### 正常系
- [ ] 正しいパスワードでのアカウント削除成功
- [ ] Firebase Auth削除の確認
- [ ] Cloud SQLからの完全削除確認
- [ ] 未ログインページへの自動遷移確認

### 異常系
- [ ] 間違ったパスワードでの削除失敗
- [ ] 試行回数制限の動作確認
- [ ] ネットワークエラー時の動作確認
- [ ] 部分失敗時の状態確認

### セキュリティ
- [ ] 再認証なしでの削除試行（失敗確認）
- [ ] トークン期限切れ時の動作確認
- [ ] 不正なパラメータでのAPI呼び出し確認

## 今後の改善案

1. **データバックアップ機能**: 削除前のデータエクスポート機能
2. **削除猶予期間**: 30日間の削除猶予期間設定
3. **削除理由収集**: 退会理由のフィードバック収集機能
4. **管理者通知**: アカウント削除の管理者通知機能

---
*最終更新: 2025-09-17*
*実装完了度: 100%*