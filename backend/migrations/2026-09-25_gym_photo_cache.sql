-- ジム写真の解決結果キャッシュ（Issue #89 対策 E）: gym_photo_cache テーブル
-- 冪等（何度流しても同じ結果）。追加のみ（DROP・既存データの書き換えなし）。
-- 適用: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/2026-09-25_gym_photo_cache.sql
--
-- 目的:
-- - 従来は services/placesService.ts がプロセス内メモリ（Map）に 7 日キャッシュしていたため、
--   Cloud Run の再起動・デプロイ・スケール（dev はほぼ毎回）で消え、Google Places（従量課金）へ取り直していた。
-- - このテーブルに置くことで、再起動しても残り、取り直しは「ジムごとに 30 日に 1 回」を上限にできる。
--
-- 保存するもの（Google Places 規約の範囲内）:
-- - 保存するのは短命の写真 URL（photoUri）と帰属情報（authorName/authorUri）だけ。画像データは保存しない。
-- - 規約が許す「パフォーマンス目的のキャッシュ」は 30 日以内なので、expires_at は最長 30 日。
-- - 自前写真（gym_photos テーブル）はこのテーブルには入れない（元のテーブルを毎回読む）。

CREATE TABLE IF NOT EXISTS gym_photo_cache (
  gym_id     INTEGER     PRIMARY KEY REFERENCES gyms(gym_id) ON DELETE CASCADE,
  source     TEXT        NOT NULL CHECK (source IN ('google', 'none')),
  photos     JSONB       NOT NULL DEFAULT '[]'::jsonb,   -- [{url, authorName, authorUri}, ...]
  expires_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 期限切れ行の掃除用（運用で `DELETE FROM gym_photo_cache WHERE expires_at < now()` を流すときに使う）
CREATE INDEX IF NOT EXISTS idx_gym_photo_cache_expires ON gym_photo_cache(expires_at);
