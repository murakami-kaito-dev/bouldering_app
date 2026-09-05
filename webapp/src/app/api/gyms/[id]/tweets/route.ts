import { NextResponse, type NextRequest } from "next/server";
import { ApiError } from "@/lib/api/client";
import { getGymTweets } from "@/lib/api/gyms";
import { parseGymId } from "@/components/gym/detail/gymId";
import { isValidCursor } from "@/components/gym/detail/tweetsPage";

const DEFAULT_LIMIT = 10;
const MAX_LIMIT = 50;

/**
 * BFF: ジムのボル活をページングで返す（ブラウザはバックエンドを直接叩かない）。
 * GET /api/gyms/[id]/tweets?cursor=&limit=  →  { items: Tweet[], nextCursor: string | null }
 * cursor は最後の項目の tweetedAt（ISO8601）。
 */
export async function GET(req: NextRequest, ctx: RouteContext<"/api/gyms/[id]/tweets">) {
  const { id: rawId } = await ctx.params;
  const id = parseGymId(rawId);
  if (id === null) return NextResponse.json({ error: "ジム ID が不正です" }, { status: 400 });

  const sp = req.nextUrl.searchParams;
  const limitRaw = Number(sp.get("limit") ?? DEFAULT_LIMIT);
  const limit = Number.isInteger(limitRaw) ? Math.min(Math.max(limitRaw, 1), MAX_LIMIT) : DEFAULT_LIMIT;
  const cursorRaw = sp.get("cursor");
  if (cursorRaw && !isValidCursor(cursorRaw)) return NextResponse.json({ error: "cursor が不正です" }, { status: 400 });
  const cursor = cursorRaw && isValidCursor(cursorRaw) ? cursorRaw : null;

  try {
    const page = await getGymTweets(id, limit, cursor);
    return NextResponse.json(page, {
      headers: { "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300" },
    });
  } catch (e) {
    if (e instanceof ApiError) {
      const status = e.status === 404 ? 404 : e.status === 400 ? 400 : 502;
      return NextResponse.json({ error: e.message }, { status });
    }
    console.error("[api/gyms/[id]/tweets] failed:", e);
    return NextResponse.json({ error: "ボル活を取得できませんでした" }, { status: 502 });
  }
}
