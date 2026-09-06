# 通知・お知らせ API — 台帳用メモ（Issue #81 / `feature/notifications`）

API 一覧スプレッドシート「イワノボリタイ_バックエンドAPI一覧」に転記する行（`.claude/rules/api-catalog.md` の 12 列）。
`No.` はシート側で振り直す（ここでは いいね 2 本・コメント 3 本の続きとして仮番号 49〜52）。
仕様は `social-spec.md`「3. 通知」（2026-09-06 チーム間契約）。

## API 一覧タブへ追加する行

| No. | カテゴリ | メソッド | パス | 概要 | 認証 | パスパラメータ | クエリ・ボディ | レスポンス(200) | 主なエラー | 定義場所 | 備考 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 49 | 通知 | GET | `/api/users/:user_id/notifications` | 本人の通知一覧（新しい順）。**いいねは同じツイートへのものを 1 行に集約**（`actors` は新しい順に最大 6 人、`actor_count` が総数）。ブロック関係のアクターは除外 | 必須（本人のみ） | `user_id` | query `limit`(1..100, 既定 30) / `cursor`(ISO8601: 前ページ最後の `created_at`。これより古いものを返す) | `{ success, data: [{ notification_id(代表行), type('like'\|'comment'\|'reply'), actors: [{ user_id, user_name, user_icon_url }], actor_count, tweet: { tweet_id, gym_name, content_head(40字) }\|null, comment: { comment_id, content_head(40字。削除済みは "") }\|null, is_read, created_at }] }` | 400 validation / 401 / 403 本人以外 | `routes/notifications.ts:49` | 集約の単位は「同じツイート × 日本時間の同じ日」（下記）。`is_read` はグループ内が全て既読のとき true |
| 50 | 通知 | GET | `/api/users/:user_id/notifications/unread-count` | 未読数（一覧と同じ集約単位で数える＝バッジの数） | 必須（本人のみ） | `user_id` | — | `{ success, data: { count } }` | 401 / 403 | `routes/notifications.ts:75` | ポーリングはしない（アプリは起動・タブ表示・復帰時に取得） |
| 51 | 通知 | POST | `/api/users/:user_id/notifications/read` | 既読化。`up_to_id` があればその ID 以下、無ければ全部 | 必須（本人のみ） | `user_id` | body `{ up_to_id?: int≥1 }` | `{ success, data: { updated } }`（更新した行数） | 400 validation / 401 / 403 | `routes/notifications.ts:98` | 冪等（既読済みは数えない） |
| 52 | お知らせ | GET | `/api/announcements` | 公式（`gym_id` NULL）のお知らせ＋認証時は本人のホームジム（`users.home_gym_id`）・イキタイジム（`gym_favorites`）のお知らせ。新しい順。`published_at` が未来のものは出さない | 任意 | — | query `limit`(1..100, 既定 20) / `cursor`(ISO8601: 前ページ最後の `published_at`) | `{ success, data: [{ announcement_id, gym_id\|null, gym_name\|null, title, body, image_url, link_url, published_at }] }` | 400 validation | `routes/announcements.ts:19` | 投稿 API は無い（当面は DB へ直接 INSERT で運用）。アプリ側は `FeatureFlags.showAnnouncementsTab = false` で非表示 |

改訂履歴タブ: `2026-09-06 / 追加 / 通知 API 3 本・お知らせ API 1 本を追加 / feature/notifications / Claude`

## イベント → 通知の生成ルール（`services/notificationService.ts`）

購読は `dependencies.ts` の `setupEventSystem()` で `getNotificationService().registerHandlers(eventBus)`。
ハンドラー内の失敗はログのみ（いいね／コメント自体には影響しない）。

| イベント | 生成 | 除外 |
|---|---|---|
| `TweetLiked { tweetId, tweetOwnerUserId, likerUserId }` | 投稿者へ `like`（`ON CONFLICT DO NOTHING`＝(受信者, アクター, ツイート) で一意） | 投稿者＝いいねした人／ブロック関係 |
| `TweetUnliked { tweetId, likerUserId }` | 対応する `like` 通知（アクター × ツイート）を削除 | — |
| `CommentCreated { commentId, tweetId, tweetOwnerUserId, commenterUserId, parentCommentId?, parentCommentOwnerUserId? }` | 親コメントがあれば親の投稿者へ `reply`。投稿者へ `comment`（**投稿者＝親コメント主なら `reply` の 1 件だけ**） | 自分自身／ブロック関係 |

### いいねの集約（`PostgresNotificationRepository`）

- 仕様の「同じツイートに対する 24 時間以内のいいねを 1 行に」は、**同じツイート × 日本時間（Asia/Tokyo）の同じ日** を 1 グループとして実装した。
  - 理由: 「代表行から 24 時間」をそのまま実装するとグループがページ境界に依存し、カーソル方式のページングで重複・欠落が起きる。日付で区切ればグループ鍵が決定的になり、カーソル＝代表行の `created_at` で重複なく次ページが取れる
- 代表行＝グループ内で最新の行（`notification_id` もそれ）。`created_at` は代表行のもの。`is_read` は `bool_and`
- `comment` / `reply` は 1 行 = 1 グループ

## DB マイグレーション

- `backend/migrations/2026-09-06_notifications.sql`（冪等・追加のみ。内容は仕様どおり）
  - `notifications`（notification_id BIGSERIAL / recipient_user_id / actor_user_id / type CHECK('like','comment','reply') / tweet_id / comment_id / is_read / created_at。FK は全て ON DELETE CASCADE）
  - `idx_notifications_recipient (recipient_user_id, created_at DESC)`、部分ユニーク `uq_notifications_like (recipient_user_id, actor_user_id, tweet_id) WHERE type='like'`
  - `announcements`（announcement_id / gym_id NULL=公式 / title / body / image_url / link_url / published_at / created_at）、`idx_announcements_pub`
- **dev には 2026-09-06 に適用済み**（`psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f …`。CREATE TABLE ×2 / CREATE INDEX ×3 を確認）。**prod 未適用**（本番リリース時に同じファイルを流す。likes / comments のマイグレーションの後に流すこと＝`tweet_comments` への FK があるため）

## 動作確認（2026-09-06・ローカル ts-node + dev DB）

サービス層の結合テスト（一時ユーザー A/B/C と A の投稿を作り、`LikeService` / `CommentService` → イベントバス → `NotificationService` の実経路で確認。終了時に全行削除、残骸 0 を確認）:

- B がいいね → A に `like` 1 行／A が自分の投稿にいいね → 増えない／B が解除 → 行が消える
- B と C がいいね → 一覧は **1 行**（`actor_count: 2`、`actors: [C, B]`＝新しい順、`tweet.gym_name`＋`content_head` 40 字）、未読数 1
- B がコメント → A に `comment`（`comment.content_head` にコメント本文）／A が B のコメントに返信 → B に `reply`、A 自身には増えない／B が A のコメント（投稿者）に返信 → A に **`reply` の 1 件だけ**（`comment` は作らない）
- カーソル: `limit=2` → 2 行、`cursor=<2 行目の created_at>` → 残り 1 行（重複なし）
- 既読: `up_to_id=<like グループの代表 ID>` → そのグループごと既読になり未読 2／`up_to_id` 無し → 未読 0
- ブロック: A が C をブロック → 一覧の like 行から C が消え `actor_count: 1`。ブロック中の C がコメント → 通知行は作られない
- お知らせ: 公式 1・ジム1（A のホームジム）・ジム2（A のイキタイ）・未来日付の公式 1 を投入 → 未認証は公式 1 件のみ、A 認証は 3 件（`gym_name` JOIN 済み）。未来のものは出ない
- HTTP（`PORT=8099` でローカル起動、未認証）: `/health` healthy／通知 3 本ともトークン無し → 401、偽トークン → 401／`GET /api/announcements` → 200 `[]`／`limit=0`・`cursor=abc` → 400／既存の `/api/users/:id/profile` は従来どおり（マウント順の影響なし）
- `tsc --noEmit`: エラーなし
- 未実施: Firebase ID トークン付きの HTTP 経由テスト（403 の本人チェックを含む）。実機（fdev）で B のいいね → A の端末に通知バッジ・一覧・既読化・詳細への遷移を確認する
