/**
 * URL の `[id]` を数値に。数字以外・空・巨大値は null（呼び出し側で 404 に倒す）。
 * バックエンドは非数値に 400 を返すので、ここで弾いて不要な往復を避ける。
 */
export function parseGymId(raw: string | undefined | null): number | null {
  if (!raw || !/^\d{1,9}$/.test(raw)) return null;
  const n = Number(raw);
  return n > 0 ? n : null;
}
