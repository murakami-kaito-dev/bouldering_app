import { createTweet } from "@/lib/api/tweets";
import { errorResponse, isResponse, jsonError, jsonOk, readJson, requireAuth } from "@/lib/auth/server";
import { todayYmdJst } from "@/lib/gym/hours";

interface PostBody {
  gym_id?: unknown;
  tweet_contents?: unknown;
  visited_date?: unknown;
  media_urls?: unknown;
}

const MAX_CONTENT = 400;
const MAX_MEDIA = 4;

/** POST /api/post → POST /tweets（ボル活投稿）。バックエンドと同じ制約をここでも先に弾く */
export async function POST(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  const body = await readJson<PostBody>(req);
  if (!body) return jsonError(400, "リクエストの形式が正しくありません");

  const gymId = typeof body.gym_id === "number" ? body.gym_id : Number.parseInt(String(body.gym_id ?? ""), 10);
  if (!Number.isInteger(gymId) || gymId < 1) return jsonError(400, "ジムを選んでください", "GYM_REQUIRED");

  const content = typeof body.tweet_contents === "string" ? body.tweet_contents : "";
  if ([...content].length > MAX_CONTENT) return jsonError(400, `本文は ${MAX_CONTENT} 文字以内にしてください`, "CONTENT_TOO_LONG");

  const visitedDate = typeof body.visited_date === "string" ? body.visited_date : "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(visitedDate)) return jsonError(400, "日付の形式が正しくありません", "DATE_INVALID");
  if (visitedDate > todayYmdJst()) return jsonError(400, "未来の日付は選べません", "DATE_FUTURE");

  const mediaUrls = Array.isArray(body.media_urls) ? body.media_urls : [];
  if (mediaUrls.length > MAX_MEDIA) return jsonError(400, `写真は ${MAX_MEDIA} 枚までです`, "MEDIA_TOO_MANY");
  if (!mediaUrls.every((u) => typeof u === "string" && /^https:\/\//.test(u))) return jsonError(400, "写真の URL が正しくありません", "MEDIA_INVALID");

  try {
    const tweet = await createTweet({ gymId, content, visitedDate, mediaUrls: mediaUrls as string[] }, ctx.token);
    return jsonOk(tweet, 201);
  } catch (e) {
    return errorResponse(e);
  }
}
