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
 * - コスト対策として解決結果をサーバ内メモリに TTL 付きでキャッシュする
 *   （規約の「パフォーマンス目的の30日以内キャッシュ」許容の範囲内）
 * - source='google' の写真は、フロント側で Google 帰属表示を行うこと（規約必須）
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

/** 成功結果のキャッシュ期間: 7日（Places呼び出し回数の上限を「ジム数×週1」に抑える） */
const SUCCESS_TTL_MS = 7 * 24 * 60 * 60 * 1000;

/** 失敗・写真なし結果のキャッシュ期間: 短めにして復旧を早くする */
const EMPTY_TTL_MS = 60 * 60 * 1000;

interface CacheEntry {
  expiresAt: number;
  result: GymPhotosResult;
}

const cache = new Map<number, CacheEntry>();

export async function getGymPhotos(gymId: number): Promise<GymPhotosResult> {
  const cached = cache.get(gymId);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.result;
  }

  const result = await resolvePhotos(gymId);
  const ttl = result.photos.length > 0 ? SUCCESS_TTL_MS : EMPTY_TTL_MS;
  cache.set(gymId, { expiresAt: Date.now() + ttl, result });
  return result;
}

async function resolvePhotos(gymId: number): Promise<GymPhotosResult> {
  // 1. 自前写真（許諾取得済み・GCS保存）があれば最優先
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

  // 2. Places API（place_id 未解決・キー未設定なら写真なし）
  if (!config.places.apiKey) {
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
