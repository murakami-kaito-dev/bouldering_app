-- 通知タブ（Issue #81）のスキーマ
-- 仕様: social-spec.md「3. 通知」。冪等（IF NOT EXISTS）・追加のみ。
-- 適用: dev のみ（psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/2026-09-06_notifications.sql）
--
-- 設計の要点:
-- - notifications: いいね／コメント／返信のアプリ内通知。イベント購読（TweetLiked / TweetUnliked / CommentCreated）で生成する
-- - like 通知は (受信者, アクター, ツイート) で一意（部分ユニーク索引）。いいね解除で同じキーの行を消す
-- - announcements: 運営の公式お知らせ（gym_id NULL）と、ジムからのお知らせ（gym_id あり）

CREATE TABLE IF NOT EXISTS notifications (
  notification_id   BIGSERIAL PRIMARY KEY,
  recipient_user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  actor_user_id     TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  type              TEXT NOT NULL CHECK (type IN ('like','comment','reply')),
  tweet_id          INTEGER NULL REFERENCES tweets(tweet_id) ON DELETE CASCADE,
  comment_id        INTEGER NULL REFERENCES tweet_comments(comment_id) ON DELETE CASCADE,
  is_read           BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_like ON notifications(recipient_user_id, actor_user_id, tweet_id) WHERE type = 'like';

CREATE TABLE IF NOT EXISTS announcements (
  announcement_id SERIAL PRIMARY KEY,
  gym_id       INTEGER NULL REFERENCES gyms(gym_id) ON DELETE CASCADE,  -- NULL = 運営の公式お知らせ
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  image_url    TEXT NULL,
  link_url     TEXT NULL,
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_announcements_pub ON announcements(published_at DESC);
