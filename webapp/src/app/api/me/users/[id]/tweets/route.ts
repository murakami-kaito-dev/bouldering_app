import { getUserTweets } from "@/lib/api/tweets";
import { errorResponse, jsonError, jsonOk } from "@/lib/auth/server";

/** GET /api/me/users/:id/tweets?cursor= → 公開プロフィールのボル活（認証不要。/users/[id] の「もっと見る」用） */
export async function GET(req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(id)) return jsonError(400, "ユーザー ID が正しくありません");
  const cursor = new URL(req.url).searchParams.get("cursor");
  try {
    const page = await getUserTweets(id, 20, cursor);
    return jsonOk(page);
  } catch (e) {
    return errorResponse(e);
  }
}
