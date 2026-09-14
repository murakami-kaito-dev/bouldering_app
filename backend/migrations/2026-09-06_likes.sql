-- いいね機能（Issue #17）: tweet_likes テーブル
-- 冪等（何度流しても同じ結果）。追加のみ（DROP・既存データの書き換えなし）。
-- 適用: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/2026-09-06_likes.sql
-- tweets.liked_counts（既存列）は非正規化カウンタとして、いいね／解除と同一トランザクションで ±1 する。

CREATE TABLE IF NOT EXISTS tweet_likes (
  user_id    TEXT        NOT NULL REFERENCES users(user_id)   ON DELETE CASCADE,
  tweet_id   INTEGER     NOT NULL REFERENCES tweets(tweet_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, tweet_id)
);

CREATE INDEX IF NOT EXISTS idx_tweet_likes_tweet ON tweet_likes(tweet_id);
