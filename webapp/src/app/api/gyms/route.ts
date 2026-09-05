import { getAllGyms } from "@/lib/api/gyms";
import { toGymSummary, type GymSummaryResponse } from "@/lib/gym/search";

/**
 * BFF: 全ジムの軽量版（GymSummary）。検索ページのブラウザ側が絞り込み用に一度だけ取得する。
 * バックエンドへは `getAllGyms`（Next の fetch キャッシュ 1h）経由なので、ブラウザから直接 Cloud Run を叩かない。
 */
export async function GET() {
  try {
    const gyms = (await getAllGyms()).map(toGymSummary);
    const body: GymSummaryResponse = { total: gyms.length, gyms };
    return Response.json(body, {
      headers: {
        "Cache-Control": "public, max-age=300, s-maxage=3600, stale-while-revalidate=600",
      },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : "ジム一覧の取得に失敗しました";
    return Response.json({ message }, { status: 502, headers: { "Cache-Control": "no-store" } });
  }
}
