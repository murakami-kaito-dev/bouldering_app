import type { NextRequest } from "next/server";
import { ApiError } from "@/lib/api/client";
import { getAllTweets } from "@/lib/api/tweets";

/**
 * みんなのボル活の BFF（ブラウザはバックエンドを直接呼ばない）。
 * GET /api/tweets?limit=20&cursor=<tweet_id>
 * → { items: Tweet[], nextCursor: string | null }
 * バックエンド側の読み取りは getAllTweets（fetch revalidate 60s）でキャッシュされる。
 */
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

/**
 * バックエンドのカーソルは ISO8601 の日時（`tweeted_date < cursor`、validatePagination で isISO8601）。
 * 共通ライブラリ getAllTweets() は nextCursor に tweet_id を入れてしまうため（要修正・lib 側）、
 * ここでは最後の投稿の tweetedAt から正しいカーソルを組み直す。
 */
const ISO_CURSOR = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/;

export async function GET(req: NextRequest) {
  const sp = req.nextUrl.searchParams;

  const limitRaw = Number(sp.get("limit") ?? DEFAULT_LIMIT);
  const limit = Number.isFinite(limitRaw) ? Math.min(MAX_LIMIT, Math.max(1, Math.floor(limitRaw))) : DEFAULT_LIMIT;

  // カーソルは ISO8601 の日時（前ページ最後の tweetedAt）。形式外は無視して先頭から
  const cursorRaw = sp.get("cursor");
  const cursor = cursorRaw && ISO_CURSOR.test(cursorRaw) && !Number.isNaN(Date.parse(cursorRaw)) ? cursorRaw : null;

  try {
    const { items } = await getAllTweets(limit, cursor);
    const page = { items, nextCursor: items.length === limit ? items[items.length - 1].tweetedAt : null };
    return Response.json(page, {
      headers: { "Cache-Control": "public, max-age=30, s-maxage=60, stale-while-revalidate=300" },
    });
  } catch (e) {
    const status = e instanceof ApiError && e.status >= 400 && e.status < 500 ? e.status : 502;
    return Response.json({ error: "ボル活を取得できませんでした" }, { status, headers: { "Cache-Control": "no-store" } });
  }
}
