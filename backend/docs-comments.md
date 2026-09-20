# スレッド（コメント・返信）API — 台帳用メモ（Issue #19 / `feature/comment-threads`）

API 一覧スプレッドシート「イワノボリタイ_バックエンドAPI一覧」に転記する行（`.claude/rules/api-catalog.md` の 12 列）。
`No.` はシート側で振り直す（ここでは既存 45 件の続きとして仮番号 46〜48）。

| No. | カテゴリ | メソッド | パス | 概要 | 認証 | パスパラメータ | クエリ・ボディ | レスポンス(200) | 主なエラー | 定義場所 | 備考 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 46 | コメント | GET | `/api/tweets/:tweet_id/comments` | ツイートのコメント一覧（作成日時 **昇順**・フラット。削除済みは `is_deleted: true`・`content: ""` で返す。ログイン時はブロック関係のユーザーのコメントを除外） | 任意 | `tweet_id`(int≥1) | query `limit`(1..100, 既定 50) / `cursor`(ISO8601: 前ページ最後の `created_at`。これより後を返す) | `{ success, data: [{ comment_id, tweet_id, user_id, user_name, user_icon_url, parent_comment_id, root_comment_id, reply_to_user_id, reply_to_user_name, content, is_deleted, created_at }] }` | 400 validation | `routes/comments.ts:46`（tweetCommentsRouter） | カーソル比較はミリ秒に丸める（JSON の `created_at` はミリ秒精度） |
| 47 | コメント | POST | `/api/tweets/:tweet_id/comments` | コメント投稿。`parent_comment_id` があれば返信（`root_comment_id`=親の root か親自身、`reply_to_user_id`=親の投稿者を導出）。`tweets.comment_counts` を同一トランザクションで +1。`CommentCreatedEvent` を publish | 必須 | `tweet_id` | body `{ content: string(1..400, trim), parent_comment_id?: int }` | 201 `{ success, data: <46 の 1 要素> }` | 400 validation / 400 親が削除済み / 401 / 404 ツイート無し・親が無い(他ツイートの親も 404) | `routes/comments.ts:77` | 削除済みの親には返信できない |
| 48 | コメント | DELETE | `/api/comments/:comment_id` | 論理削除（`is_deleted=true`・`content=''`・`deleted_at`）。**コメント本人 または そのツイートの投稿者**のみ。`comment_counts` を −1（既に削除済みなら何もしない＝冪等） | 必須 | `comment_id`(int≥1) | — | `{ success, data: { comment_id, is_deleted: true } }` | 401 / 403 本人でも投稿者でもない / 404 | `routes/comments.ts:124`（commentsRouter） | 物理削除しないので、下にぶら下がる返信は残る |

## 既存 API の変更（同 PR）

- ツイート一覧・詳細（`GET /tweets`, `/tweets/:id`, `/tweets/users/:id`, `/gyms/:id/tweets`, `/users/:id/favorites/users/tweets`）のレスポンスに **`comment_counts`**（非削除コメント数）を追加。
  - 定義場所: `PostgresTweetRepository.ts`（5 クエリ）／`PostgresGymRepository.ts`（2）／`PostgresFavoriteRepository.ts`（2）の SELECT に `t.comment_counts` を追加。`models/types.ts` の `Tweet` にも追加。

## DB マイグレーション

- `backend/migrations/2026-09-06_comments.sql`（冪等・追加のみ）
  - `tweet_comments`（comment_id / tweet_id / user_id / parent_comment_id / root_comment_id / reply_to_user_id / content / is_deleted / created_at / updated_at / deleted_at）
  - `idx_tweet_comments_tweet (tweet_id, created_at)`
  - `ALTER TABLE tweets ADD COLUMN IF NOT EXISTS comment_counts INTEGER NOT NULL DEFAULT 0`
- **dev には 2026-09-06 に適用済み**（`psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f …`。CREATE TABLE / CREATE INDEX / ALTER TABLE を確認）。**prod 未適用**（本番リリース時に同じファイルを流す）。

## ドメインイベント

- `domain/events/CommentCreatedEvent.ts` — `eventType: 'CommentCreated'`、`{ commentId, tweetId, tweetOwnerUserId, commenterUserId, parentCommentId?, parentCommentOwnerUserId? }`。`commentService.createComment` が publish（購読者は通知チームが `dependencies.ts` の `setupEventSystem()` で登録する）。

## 動作確認（2026-09-06・ローカル起動 `ts-node` + dev DB・dev Firebase の一時アカウント 2 つ）

シナリオ: A が投稿 → B がルート c1 → A が c1 に返信 c2 → B が c2 に返信 c3（返信への返信）。

- 作成レスポンス: c2 は `parent_comment_id=1, root_comment_id=1, reply_to_user_name=B`、c3 は `parent=2, root=1, reply_to=A` ＝ 仕様どおりの導出
- `comment_counts`: 0 → 3（詳細 `GET /tweets/:id` で確認）
- **A が真ん中の c2 を削除** → 一覧は `[c1, c2(is_deleted=true, content=""), c3]` を返し、c3 は残る。`comment_counts` は 2
- 権限: B（本人でも投稿者でもない）が A のコメントを削除 → **403**。投稿者 A が B の c1 を削除 → **200**。同じコメントの二重削除 → 200（カウンタ据え置き＝冪等）
- バリデーション: 空白のみ → 400、401 文字 → 400、未認証 POST → 401、削除済み親への返信 → 400、他ツイートの親 → 404、存在しないコメント削除 → 404
- カーソル: `limit=2` → `[c1, c2]`、`cursor=<c2.created_at>` → `[c3]`（初回はミリ秒の丸めが無く c2 が再度返るバグがあり修正済み）
- 一覧 `GET /tweets?limit=1` の要素に `comment_counts` が含まれる
- ブロック除外: 認証付き GET で NOT IN 分岐の SQL が実行されることまで確認（実際にブロック関係を作っての除外確認は未実施＝ツイート一覧と同じ句なので同挙動の想定）
- 後片付け: 検証ツイート削除（CASCADE でコメント 0 行）・DB ユーザー削除・Firebase 一時アカウント削除まで完了
