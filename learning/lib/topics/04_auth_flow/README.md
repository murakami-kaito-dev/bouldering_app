# 04 認証フローとトークン管理

## 本体での対応箇所

- `lib/infrastructure/services/firebase_auth_service.dart` — Firebase Auth のラッパ
- `lib/infrastructure/services/api_client.dart:42-90` — **毎リクエストで `getIdToken()` を呼び `Authorization: Bearer` を自動付与**
- `lib/presentation/pages/app.dart` — アプリがフォアグラウンド復帰したときのトークン失効チェック
- `lib/presentation/providers/auth_provider.dart` — ログイン/ログアウト/退会などの操作
- バックエンド側: `backend/src/middleware/auth.ts` — Firebase Admin SDK で `verifyIdToken`

## 本体の認証の全体像

```
Flutter ──メール+パスワード──▶ Firebase Auth ──▶ IDトークン(JWT, 1時間有効)
Flutter ──API呼び出し(Bearer IDトークン)──▶ Cloud Run
Cloud Run ── Firebase Admin SDK で verifyIdToken ──▶ req.user = { uid, ... }
各ハンドラ ── req.user.uid === パスの user_id か確認（認可）
```

## 学べるポイント

1. **トークン付与は1箇所に集約**: 画面やUseCaseは認証を意識しない。ApiClientが毎回付ける。
2. **認証(Authentication) と 認可(Authorization) は別物**: トークン検証が認証、「本人のデータか」の確認が認可。本体は認可を各ハンドラで `uid === user_id` 比較している（13回コピペ → ミドルウェア化が本体のリファクタ候補）。
3. **失効検知**: 401が返ったら強制ログアウト。**statusCodeを握り潰さない**ことが大事（本体には例外二重ラップでstatusCodeが失われるバグ候補 `api_client.dart:103-131` があった）。
4. **本物のFirebaseとの差分**: 本物のSDKは `getIdToken()` 内で自動リフレッシュするため、通常は期限切れにならない。失効するのは「パスワード変更・アカウント無効化・リフレッシュトークン破棄」のとき。このミニアプリは15秒で強制失効させて、その稀なケースの挙動を観察できるようにしている。

## 面接での定番質問

- 「トークンはどこに保存しますか？」→ 本体はFirebase SDKに任せている（Keychain管理）。自前実装なら iOS Keychain / Android Keystore。SharedPreferences 平文保存はNG。
- 「JWTの検証はクライアントとサーバどちらで？」→ サーバ（署名検証）。クライアント側の期限チェックはUX改善にすぎない。
- 「ログアウトでトークンは無効になりますか？」→ IDトークン自体は期限まで有効（ステートレス）。即時無効化にはリフレッシュトークンの破棄＋サーバ側のrevocationチェックが必要。

## あえて削ぎ落としたもの

- Firebase SDK 本体（Fakeで再現）
- 新規登録・パスワードリセット・再認証（構造は同じ）
- AppLifecycleState 監視（本体は `app.dart` の `didChangeAppLifecycleState` で復帰時チェック）
