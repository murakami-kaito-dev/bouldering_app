-- コンペティション機能（デモ・dev 先行）: ジム管理者・コンペ・参加・完登記録
-- 冪等（何度流しても同じ結果）。追加のみ（DROP・既存データの書き換えなし）。
-- 適用: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/2026-10-03_competitions.sql
--
-- 設計の要点:
-- - ジム管理者は users.managed_gym_id（NULL = 一般ユーザー）で表す。登録は運営が DB を直接更新する運用
-- - 期間は日本時間の「日付」で持つ（DATE 列・'YYYY-MM-DD'）。開始日 00:00:00 〜 終了日 23:59:59 JST。
--   開催中かどうかの判定はバックエンドが jstToday() と比較して行う（DB の now() は使わない）
-- - 課題は problem_from〜problem_to の整数連番。1 課題 = 1 点
-- - 参加料 entry_fee_yen は保存するだけ（決済は未実装。参加は無料扱い）
-- - 同じジムが同時に複数のコンペを開催できる（期間の重なりを禁止しない）
-- - 順位 = 完登数（competition_results の行数）が多い順。同数は同順位

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS managed_gym_id INTEGER NULL REFERENCES gyms(gym_id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS competitions (
  competition_id SERIAL PRIMARY KEY,
  gym_id         INTEGER     NOT NULL REFERENCES gyms(gym_id)   ON DELETE CASCADE,
  host_user_id   TEXT        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  title          TEXT        NOT NULL DEFAULT '',          -- 任意。空ならアプリ側で「<ジム名> のコンペ」と表示
  start_date     DATE        NOT NULL,                     -- JST の日付
  end_date       DATE        NOT NULL,                     -- JST の日付（この日の 23:59:59 まで）
  problem_from   INTEGER     NOT NULL,
  problem_to     INTEGER     NOT NULL,
  entry_fee_yen  INTEGER     NOT NULL DEFAULT 0,           -- 0 = 無料
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_competitions_period  CHECK (end_date >= start_date),
  CONSTRAINT chk_competitions_problem CHECK (problem_from >= 1 AND problem_to >= problem_from),
  CONSTRAINT chk_competitions_fee     CHECK (entry_fee_yen >= 0)
);
CREATE INDEX IF NOT EXISTS idx_competitions_gym    ON competitions(gym_id);
CREATE INDEX IF NOT EXISTS idx_competitions_period ON competitions(start_date, end_date);

-- 参加（1 ユーザー 1 コンペ 1 行）
CREATE TABLE IF NOT EXISTS competition_entries (
  competition_id INTEGER     NOT NULL REFERENCES competitions(competition_id) ON DELETE CASCADE,
  user_id        TEXT        NOT NULL REFERENCES users(user_id)               ON DELETE CASCADE,
  joined_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (competition_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_competition_entries_user ON competition_entries(user_id);

-- 完登記録（参加者が自己申告。1 課題 1 行。取り消しは DELETE）
CREATE TABLE IF NOT EXISTS competition_results (
  competition_id INTEGER     NOT NULL,
  user_id        TEXT        NOT NULL,
  problem_no     INTEGER     NOT NULL,
  completed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (competition_id, user_id, problem_no),
  FOREIGN KEY (competition_id, user_id)
    REFERENCES competition_entries(competition_id, user_id) ON DELETE CASCADE
);
