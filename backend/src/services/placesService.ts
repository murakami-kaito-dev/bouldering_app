import { config } from '../config/environment';
import { db } from '../config/database';
import logger from '../utils/logger';

/**
 * ジム写真取得サービス
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Application Service 層
 * - ジム写真の取得元を一元管理する（呼び出し側は出どころを意識しない）
 *
 * 写真の解決順序:
 *   1. 自前写真（gym_photos テーブル / GCS 保存の許諾済み写真）があればそれを返す
 *   2. なければ Google Places API (New) から取得する
 *
 * Google Places API の規約対応:
 * - 写真データ自体の保存は規約で禁止されているため、保存するのは place_id のみ
 *   （gyms.google_place_id 列。place_id は無期限保存が明示的に許可されている）
 * - 写真は表示のたびに短命URL（Google CDN の photoUri）を解決して返す
 * - コスト対策として解決結果（URL と帰属情報だけ）を gym_photo_cache テーブルに TTL 付きで保存する
 *   （規約の「パフォーマンス目的の30日以内キャッシュ」許容の範囲内。Issue #89 対策 E・2026-09-25）
 * - source='google' の写真は、フロント側で Google 帰属表示を行うこと（規約必須）
 *
 * キャッシュの 2 段構え:
 * - L1: プロセス内メモリ（短時間）。地図や一覧が同じジムを連打したときに DB へ行かないためのもの。
 *       再起動で消えてよい
 * - L2: gym_photo_cache テーブル（成功 30 日 / 写真なし 1 時間）。Cloud Run の再起動・デプロイ・
 *       スケールで消えないので、Google への取り直しは「ジムごとに 30 日に 1 回」が上限になる
 *
 * 環境差分（恒久・.claude/rules/places-photos-dev-prod.md）:
 * - dev は PLACES_PHOTOS_ENABLED=false かつ PLACES_API_KEY 無しで運用し、Google へは一切問い合わせない
 */

export interface GymPhoto {
  url: string;
  authorName: string | null;
  authorUri: string | null;
}

export interface GymPhotosResult {
  /** 'own' = 自前写真 / 'google' = Places API / 'none' = 写真なし */
  source: 'own' | 'google' | 'none';
  photos: GymPhoto[];
}

/** 1ジムあたりの最大写真枚数（コストと表示バランスの妥協点） */
const MAX_PHOTOS = 5;

/** L2（DB）成功結果の保持期間: 30 日（Google Places 規約が許すキャッシュの上限） */
const DB_SUCCESS_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/** L2（DB）写真なし結果の保持期間: 短めにして復旧を早くする */
const DB_EMPTY_TTL_MS = 60 * 60 * 1000;

/**
 * L1（メモリ）の保持期間: 10 分（2026-09-25 ユーザー決定）
 * - 用途は「地図・一覧が同じジムを連打したときに DB へ行かない」ための短い一次キャッシュ
 * - 長くしない理由: 自前写真の追加や gym_photo_cache の更新が、このインスタンスに反映されるまでの
 *   最大待ち時間がこの値になる（旧実装の 7 日では、追加した自前写真が最長 7 日間出なかった）
 */
const MEMORY_TTL_MS = 10 * 60 * 1000;

interface CacheEntry {
  expiresAt: number;
  result: GymPhotosResult;
}

const memoryCache = new Map<number, CacheEntry>();

interface CacheRow {
  source: 'google' | 'none';
  photos: GymPhoto[];
  expires_at: string | Date;
}

export async function getGymPhotos(gymId: number): Promise<GymPhotosResult> {
  // L1: プロセス内メモリ
  const mem = memoryCache.get(gymId);
  if (mem && mem.expiresAt > Date.now()) {
    return mem.result;
  }

  // 1. 自前写真（許諾取得済み・GCS保存）があれば最優先。DB が正なのでキャッシュには入れない
  const own = await findOwnPhotos(gymId);
  if (own) {
    memoryCache.set(gymId, { expiresAt: Date.now() + MEMORY_TTL_MS, result: own });
    return own;
  }

  // L2: gym_photo_cache テーブル（期限内なら Google へ行かない）
  const cachedRow = await readDbCache(gymId);
  if (cachedRow) {
    const result: GymPhotosResult = { source: cachedRow.source, photos: cachedRow.photos };
    memoryCache.set(gymId, { expiresAt: Date.now() + MEMORY_TTL_MS, result });
    return result;
  }

  // 2. Google Places（無効化・キー未設定・place_id 未解決なら写真なし）
  const result = await resolveGooglePhotos(gymId);
  await writeDbCache(gymId, result);
  memoryCache.set(gymId, { expiresAt: Date.now() + MEMORY_TTL_MS, result });
  return result;
}

/** 自前写真（gym_photos）。無ければ null */
async function findOwnPhotos(gymId: number): Promise<GymPhotosResult | null> {
  try {
    const own = await db.query<{ photo_url: string }>(
      'SELECT photo_url FROM gym_photos WHERE gym_id = $1 ORDER BY photo_id LIMIT $2',
      [gymId, MAX_PHOTOS]
    );
    if (own.length > 0) {
      return {
        source: 'own',
        photos: own.map((r) => ({ url: r.photo_url, authorName: null, authorUri: null })),
      };
    }
  } catch (error) {
    // gym_photos テーブル未作成の環境でも photos 機能全体は落とさない
    logger.warn('gym_photos query failed (continuing with Places)', { gymId, error });
  }
  return null;
}

/** L2 読み取り。期限切れ・行なし・テーブル未作成のときは null（＝取り直す） */
async function readDbCache(gymId: number): Promise<CacheRow | null> {
  try {
    const rows = await db.query<CacheRow>(
      `SELECT source, photos, expires_at
         FROM gym_photo_cache
        WHERE gym_id = $1 AND expires_at > now()`,
      [gymId]
    );
    if (rows.length === 0) return null;
    const row = rows[0];
    return { ...row, photos: Array.isArray(row.photos) ? row.photos : [] };
  } catch (error) {
    // migration 未適用の環境でも photos 機能は止めない（メモリのみで動く）
    logger.warn('gym_photo_cache read failed (falling back to memory cache)', { gymId, error });
    return null;
  }
}

/** L2 書き込み（UPSERT）。成功 30 日 / 写真なし 1 時間 */
async function writeDbCache(gymId: number, result: GymPhotosResult): Promise<void> {
  if (result.source === 'own') return; // 自前写真は gym_photos が正
  const ttl = result.photos.length > 0 ? DB_SUCCESS_TTL_MS : DB_EMPTY_TTL_MS;
  try {
    await db.query(
      `INSERT INTO gym_photo_cache (gym_id, source, photos, expires_at, updated_at)
       VALUES ($1, $2, $3::jsonb, now() + ($4::bigint * interval '1 millisecond'), now())
       ON CONFLICT (gym_id) DO UPDATE
         SET source = EXCLUDED.source,
             photos = EXCLUDED.photos,
             expires_at = EXCLUDED.expires_at,
             updated_at = now()`,
      [gymId, result.source, JSON.stringify(result.photos), ttl]
    );
  } catch (error) {
    logger.warn('gym_photo_cache write failed (result served without persisting)', { gymId, error });
  }
}

/** Google Places から解決する。無効化・キー未設定・place_id 未解決・失敗は写真なし */
async function resolveGooglePhotos(gymId: number): Promise<GymPhotosResult> {
  // PLACES_PHOTOS_ENABLED=false の環境（dev）では Google へ一切問い合わせない（Issue #89 対策 B・2026-09-25）
  if (!config.places.photosEnabled || !config.places.apiKey) {
    return { source: 'none', photos: [] };
  }

  const rows = await db.query<{ google_place_id: string | null }>(
    'SELECT google_place_id FROM gyms WHERE gym_id = $1',
    [gymId]
  );
  const placeId = rows[0]?.google_place_id;
  if (!placeId) {
    return { source: 'none', photos: [] };
  }

  try {
    const photos = await fetchGooglePhotos(placeId);
    return { source: photos.length > 0 ? 'google' : 'none', photos };
  } catch (error) {
    logger.error('Places photo fetch failed', {
      gymId,
      error: error instanceof Error ? error.message : String(error),
    });
    return { source: 'none', photos: [] };
  }
}

/** Place Details で写真リストを取得し、各写真の短命URL（photoUri）へ解決する */
async function fetchGooglePhotos(placeId: string): Promise<GymPhoto[]> {
  const headers = {
    'X-Goog-Api-Key': config.places.apiKey,
    'X-Goog-FieldMask': 'photos',
  };

  const detailsRes = await fetch(`https://places.googleapis.com/v1/places/${placeId}`, { headers });
  if (!detailsRes.ok) {
    throw new Error(`Place Details ${detailsRes.status}`);
  }
  const details = (await detailsRes.json()) as {
    photos?: {
      name: string;
      authorAttributions?: { displayName?: string; uri?: string }[];
    }[];
  };

  const photoRefs = (details.photos ?? []).slice(0, MAX_PHOTOS);

  const resolved = await Promise.all(
    photoRefs.map(async (photo) => {
      // skipHttpRedirect=true でリダイレクトせず photoUri(JSON) を受け取る
      const mediaRes = await fetch(
        `https://places.googleapis.com/v1/${photo.name}/media?maxWidthPx=800&skipHttpRedirect=true`,
        { headers: { 'X-Goog-Api-Key': config.places.apiKey } }
      );
      if (!mediaRes.ok) return null;
      const media = (await mediaRes.json()) as { photoUri?: string };
      if (!media.photoUri) return null;

      const author = photo.authorAttributions?.[0];
      return {
        url: media.photoUri,
        authorName: author?.displayName ?? null,
        authorUri: author?.uri ?? null,
      };
    })
  );

  return resolved.filter((p): p is GymPhoto => p !== null);
}
