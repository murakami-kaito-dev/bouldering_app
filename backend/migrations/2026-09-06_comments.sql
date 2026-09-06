-- スレッド（コメント・返信）機能のスキーマ（Issue #19）
-- 仕様: social-spec.md「2. スレッド」。冪等（IF NOT EXISTS）・追加のみ。
-- 適用: dev のみ（psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/2026-09-06_comments.sql）
--
-- 設計の要点:
-- - 論理削除（is_deleted）で木構造を壊さない。途中のコメントを削除しても、その下の返信は残る
-- - parent_comment_id は DB 上は無制限の深さ。画面は root_comment_id で 2 段に畳む
-- - tweets.comment_counts は「非削除コメント数」の非正規化カウンタ（作成 +1 / 論理削除 -1、同一トランザクション）

CREATE TABLE IF NOT EXISTS tweet_comments (
  comment_id        SERIAL PRIMARY KEY,
  tweet_id          INTEGER NOT NULL REFERENCES tweets(tweet_id) ON DELETE CASCADE,
  user_id           TEXT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  parent_comment_id INTEGER NULL REFERENCES tweet_comments(comment_id) ON DELETE CASCADE,
  root_comment_id   INTEGER NULL REFERENCES tweet_comments(comment_id) ON DELETE CASCADE,
  reply_to_user_id  TEXT    NULL REFERENCES users(user_id) ON DELETE SET NULL,
  content           TEXT    NOT NULL,
  is_deleted        BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at        TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_tweet_comments_tweet ON tweet_comments(tweet_id, created_at);

ALTER TABLE tweets ADD COLUMN IF NOT EXISTS comment_counts INTEGER NOT NULL DEFAULT 0;
