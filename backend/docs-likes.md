# いいね機能（Issue #17）— API 一覧行・マイグレーション・検証記録

ブランチ `feature/likes`。仕様は `social-spec.md`「1. いいね」（2026-09-06 チーム間契約）。
API 一覧スプレッドシート（`.claude/rules/api-catalog.md`）へ転記する行と、DB 変更・検証の記録。

## API 一覧タブへ追加する行（カテゴリ「ツイート」の末尾に挿入し、No. を振り直す）

| No. | カテゴリ | メソッド | パス | 概要 | 認証 | パスパラメータ | クエリ・ボディ | レスポンス(200) | 主なエラー | 定義場所 | 備考 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| (採番) | ツイート | POST | `/api/tweets/:tweet_id/like` | ツイートにいいねを付ける。冪等（`ON CONFLICT DO NOTHING`、挿入できた時だけ `liked_counts` +1） | 必須 | `tweet_id`: 整数 ≥1 | なし（いいねする人はトークンの uid） | `{ success: true, data: { liked: true, liked_count } }` | 400 バリデーション／401 未認証／404 Tweet not found／500 | `routes/likes.ts:24` | 自分の投稿にも可。新規挿入時のみ `TweetLikedEvent` を発行（通知 #81 が購読） |
| (採番) | ツイート | DELETE | `/api/tweets/:tweet_id/like` | ツイートのいいねを外す。冪等（無ければ何もしない。削除できた時だけ `liked_counts` −1、0 未満にしない） | 必須 | `tweet_id`: 整数 ≥1 | なし | `{ success: true, data: { liked: false, liked_count } }` | 400／401／404 Tweet not found／500 | `routes/likes.ts:50` | 実際に削除された時のみ `TweetUnlikedEvent` を発行 |

### 既存行の「変更」（レスポンスに `liked_by_me: boolean` を追加）

| 対象エンドポイント | 変更内容 | 定義場所 |
|---|---|---|
| `GET /api/tweets` | 各要素に `liked_by_me`（認証時: 本人がいいね済みか／未認証: false） | `PostgresTweetRepository.getAllTweets` |
| `GET /api/tweets/:tweet_id` | 同上（`optionalAuthenticate` の uid をサービスへ渡すよう `routes/tweets.ts` を 2 行変更） | `PostgresTweetRepository.getTweetById` |
| `GET /api/tweets/users/:user_id` | 同上（同じく uid を渡す変更） | `PostgresTweetRepository.getUserTweets` |
| `GET /api/gyms/:gym_id/tweets` | 同上（`routes/gyms.ts` で uid を渡す） | `PostgresGymRepository.findGymTweets` |
| `GET /api/users/:user_id/favorites/users/tweets` | 同上（要認証・本人のみなので `$1` をそのまま使用） | `PostgresFavoriteRepository.getFavoriteUsersTweets` |

SQL 断片は `infrastructure/repositories/sqlFragments.ts` の `likedByMeSql(paramIndex)` に共通化。
`EXISTS(SELECT 1 FROM tweet_likes tl WHERE tl.tweet_id = t.tweet_id AND tl.user_id = $N)` で、
未認証時は `$N = NULL` を渡すため EXISTS が false になる（CASE 分岐不要）。

改訂履歴タブ: `2026-09-06 / 追加・変更 / いいね API 2 本追加、ツイート一覧・詳細 5 本に liked_by_me 追加 / feature/likes / Claude`

## ドメインイベント（通知チーム向け）

| クラス | `eventType` | フィールド | 発行条件 |
|---|---|---|---|
| `domain/events/TweetLikedEvent` | `TweetLiked` | `tweetId, tweetOwnerUserId, likerUserId, occurredAt` | いいねが**新規に挿入された**時のみ（二重いいねでは発行しない） |
| `domain/events/TweetUnlikedEvent` | `TweetUnliked` | `tweetId, likerUserId, occurredAt` | いいねが**実際に削除された**時のみ |

購読は `dependencies.ts` の `setupEventSystem()` で `eventBus.subscribe('TweetLiked', …)`。
発行失敗はログのみで、いいね API は成功を返す（`likeService.publishSafely`）。

## DB マイグレーション

- ファイル: `backend/migrations/2026-09-06_likes.sql`（冪等・追加のみ）
- 内容: `tweet_likes(user_id, tweet_id, created_at; PK(user_id, tweet_id); FK → users / tweets ON DELETE CASCADE)`、`idx_tweet_likes_tweet`
- **dev DB へ適用済み（2026-09-06、`psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f …`。結果 CREATE TABLE / CREATE INDEX、`\d tweet_likes` で確認）**
- **prod DB は未適用**（本番反映時に同じファイルを流す。`liked_counts` は既存列なので ALTER 不要）
- `tweets.liked_counts` は非正規化カウンタ。`PostgresLikeRepository` が対象ツイート行を `FOR UPDATE` でロックし、同一トランザクションで ±1

## 検証（2026-09-06、ローカル `npm run dev` → dev Supabase）

- `tsc --noEmit`: エラーなし
- HTTP（未認証）: `/health` healthy／`GET /api/tweets?limit=2` → `liked_by_me: false`／`GET /api/tweets/178` → false／`GET /api/tweets/users/:id` → false／`POST` `DELETE /api/tweets/178/like` トークン無し → 401、偽トークン → 401 `Invalid or expired token`
- リポジトリ結合テスト（ts-node、tweet 178 を投稿者本人 `2XIyVR…` がいいね＝自分の投稿にいいね可の確認）:
  like#1 `inserted: true, likedCount: 1` → like#2 `inserted: false, likedCount: 1`（冪等）→ 詳細(認証) `liked_by_me: true`／(未認証) false → 一覧 getAllTweets（cursor 有/無）・getUserTweets・findGymTweets すべて `liked_by_me: true`、findGymTweets(未認証) false、getFavoriteUsersTweets は SQL 正常（0 件）→ unlike#1 `deleted: true, likedCount: 0` → unlike#2 `deleted: false, likedCount: 0` → 存在しない tweet → 404。終了時 `liked_counts: 0`（データは元に戻してある）
- 未実施: Firebase ID トークン付きの HTTP 経由テスト（ローカルに ADC が無くカスタムトークンを発行できないため）。実機（fdev）でのいいね操作で確認する
