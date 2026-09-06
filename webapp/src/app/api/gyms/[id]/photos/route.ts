import { NextResponse, type NextRequest } from "next/server";
import { ApiError } from "@/lib/api/client";
import { getGymPhotos } from "@/lib/api/gyms";
import type { GymPhotosResponse } from "@/lib/api/types";
import { parseGymId } from "@/components/gym/detail/gymId";

const DEFAULT_LIMIT = 5;
const MAX_LIMIT = 5;

/**
 * BFF: ジムの写真（自前 or Google Places）。一覧カードのサムネイルがブラウザから遅延取得する。
 * GET /api/gyms/[id]/photos?limit=1  →  { source: "own" | "google" | "none", photos: GymPhoto[] }
 *
 * コスト管理（Places API 課金の抑制）:
 * - バックエンドへは `getGymPhotos`（Next の fetch キャッシュ 1 日）経由。ブラウザから直接 Cloud Run を叩かない。
 * - レスポンスにも Cache-Control（ブラウザ 1h・CDN 1 日）を付け、同じジムを何度も取りに来ないようにする。
 * - `limit` で返す枚数を絞る（カードは 1 枚だけ）。上限は API と同じ 5。
 */
export async function GET(req: NextRequest, ctx: RouteContext<"/api/gyms/[id]/photos">) {
  const { id: rawId } = await ctx.params;
  const id = parseGymId(rawId);
  if (id === null) return NextResponse.json({ error: "ジム ID が不正です" }, { status: 400 });

  const limitRaw = Number(req.nextUrl.searchParams.get("limit") ?? DEFAULT_LIMIT);
  const limit = Number.isInteger(limitRaw) ? Math.min(Math.max(limitRaw, 1), MAX_LIMIT) : DEFAULT_LIMIT;

  try {
    const data = await getGymPhotos(id);
    const body: GymPhotosResponse = { source: data.source, photos: data.photos.slice(0, limit) };
    return NextResponse.json(body, {
      headers: { "Cache-Control": "public, max-age=3600, s-maxage=86400" },
    });
  } catch (e) {
    if (e instanceof ApiError) {
      const status = e.status === 404 ? 404 : e.status === 400 ? 400 : 502;
      return NextResponse.json({ error: e.message }, { status, headers: { "Cache-Control": "no-store" } });
    }
    console.error("[api/gyms/[id]/photos] failed:", e);
    return NextResponse.json({ error: "写真を取得できませんでした" }, { status: 502, headers: { "Cache-Control": "no-store" } });
  }
}
