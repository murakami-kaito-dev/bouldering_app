# メールアドレス変更機能実装ドキュメント

## 概要

設定ページからのメールアドレス変更機能の実装詳細。Firebase Authenticationとの認証メール送信、Cloud SQLとの同期機能を含む。

## アーキテクチャ設計

### クリーンアーキテクチャ + MVVM準拠

```
Presentation層 (settings_page.dart)
    ↓
Domain層 (auth_usecases.dart)
    ↓
Infrastructure層 (firebase_auth_service.dart)
    ↓
External (Firebase Auth, Cloud SQL API)
```

## 現在の実装状態

### 1. 動作フロー
1. ユーザーが設定画面でメールアドレス変更を選択
2. `_showEmailChangeDialog`が呼び出される（StatefulWidgetダイアログ）
3. 新しいメールアドレスとパスワードを入力
4. `_executeEmailChange`メソッドで処理実行
   - Firebase Authのメールアドレス更新（認証メール送信）
   - Cloud SQLのメールアドレス更新

### 2. 実装コード（settings_page.dart）

#### メールアドレス変更ダイアログ表示
```dart
void _showEmailChangeDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _EmailChangeDialog(),
  );
  
  if (result != null && context.mounted) {
    final email = result['email'] ?? '';
    final password = result['password'] ?? '';
    await _executeEmailChange(context, ref, email, password);
  }
}
```

#### メールアドレス変更処理実行
```dart
Future<void> _executeEmailChange(
  BuildContext context,
  WidgetRef ref,
  String newEmail,
  String currentPassword,
) async {
  try {
    // 1. Firebase Authのメールアドレス更新（再認証付き）
    await ref.read(authProvider.notifier).updateEmailInFirebaseAuth(
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
    
    // 2. Cloud SQLのメールアドレス更新
    await ref.read(userProvider.notifier).updateEmail(newEmail);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('確認メールを送信しました。リンクをクリックして変更処理してください。\\nリンクをクリックした後、アプリを再起動するか、再ログインしてください。'),
          duration: Duration(seconds: 8),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メールアドレス更新に失敗しました: ${e.toString()}')),
      );
    }
  }
}
```

### 3. StatefulWidgetダイアログ実装

```dart
class _EmailChangeDialog extends StatefulWidget {
  const _EmailChangeDialog();
  
  @override
  State<_EmailChangeDialog> createState() => _EmailChangeDialogState();
}

class _EmailChangeDialogState extends State<_EmailChangeDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // build メソッド実装...
}
```

## 現在の問題

### 1回目の変更と2回目の変更の差異
- **1回目の変更**: 成功（Firebase Auth、Cloud SQL両方更新される）
- **2回目の変更**: 部分的失敗
  - Firebase Auth: 変更成功
  - Cloud SQL: 更新されない
  - エラーログ: `[firebase_auth/invalid-credential] The supplied auth credential is malformed or has expired.`

### 原因分析
認証クレデンシャルの有効期限切れまたは不正な形式により、2回目以降のメールアドレス変更時にCloud SQL更新が失敗する。

## データベース構造

```sql
-- usersテーブル
CREATE TABLE users (
  user_id VARCHAR(28) PRIMARY KEY,
  email VARCHAR(320) NOT NULL UNIQUE,
  user_name VARCHAR(255) NOT NULL,
  -- その他のカラム
);
```

## 関連ファイル構成

### Presentation層
- `/lib/presentation/pages/settings_page.dart` - 設定画面
- `/lib/presentation/providers/auth_provider.dart` - 認証状態管理
- `/lib/presentation/providers/user_provider.dart` - ユーザー状態管理

### Domain層
- `/lib/domain/services/auth_service.dart` - 認証サービスインターフェース
- `/lib/domain/usecases/auth_usecases.dart` - 認証関連ユースケース
- `/lib/domain/usecases/user_usecases.dart` - ユーザー関連ユースケース

### Infrastructure層
- `/lib/infrastructure/services/firebase_auth_service.dart` - Firebase Auth実装
- `/lib/infrastructure/datasources/user_datasource.dart` - ユーザーデータソース

### Backend（REST API）
- `/backend/src/routes/user.routes.ts` - ユーザー関連API
- エンドポイント: `PATCH /api/users/:userId/email`

## セキュリティ要件

### Firebase Auth要件
- メールアドレス変更前の再認証必須
- 認証メール確認による実際の変更実行
- パスワード要件の遵守

### データ整合性
- Firebase AuthとCloud SQLの一致保証
- トランザクション処理による原子性確保

## UI/UX設計

### ダイアログ設計
1. **新しいメールアドレス入力**: バリデーション付き
2. **現在のパスワード確認**: セキュリティ目的の説明
3. **表示/非表示切り替え**: パスワード入力補助
4. **Enterキー対応**: ユーザビリティ向上

### フィードバック
- **成功時**: 認証メールの送信説明と次のステップ案内
- **エラー時**: 具体的なエラー内容の表示

## 今後の改善点

1. **認証クレデンシャル管理の改善**: 有効期限チェックと自動更新
2. **エラーハンドリングの強化**: より詳細なエラー分類と対応
3. **ユーザー体験の向上**: プログレス表示とステップ案内
4. **セキュリティ強化**: 二要素認証対応

## テスト方法

1. **正常系**: 新しいメールアドレスでの変更成功
2. **認証メール確認**: 送信されたメールのリンククリック
3. **連続変更**: 複数回の変更でのCloud SQL同期確認
4. **エラー系**: 無効なパスワード、既存メールアドレス使用

---
*最終更新: 2025-09-17*
*実装完了度: 80% (2回目以降の変更問題あり)*