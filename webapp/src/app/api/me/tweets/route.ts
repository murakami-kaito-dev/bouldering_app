import { getUserTweets } from "@/lib/api/tweets";
import { errorResponse, isResponse, jsonOk, requireAuth } from "@/lib/auth/server";

/** GET /api/me/tweets?cursor= → GET /tweets/users/:uid（自分のボル活・新しい順） */
export async function GET(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  const cursor = new URL(req.url).searchParams.get("cursor");
  try {
    const page = await getUserTweets(ctx.uid, 20, cursor, ctx.token);
    return jsonOk(page);
  } catch (e) {
    return errorResponse(e);
  }
}
