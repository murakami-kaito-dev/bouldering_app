import { deleteTweet } from "@/lib/api/tweets";
import { errorResponse, isResponse, jsonError, jsonOk, requireAuth } from "@/lib/auth/server";

/** DELETE /api/me/tweets/:id → DELETE /tweets/:id（本人の投稿のみ。バックエンドが所有者を検証） */
export async function DELETE(req: Request, ctx: { params: Promise<{ id: string }> }) {
  const authed = requireAuth(req);
  if (isResponse(authed)) return authed;
  const { id } = await ctx.params;
  const tweetId = Number.parseInt(id, 10);
  if (!Number.isInteger(tweetId) || tweetId < 1) return jsonError(400, "投稿 ID が正しくありません");
  try {
    await deleteTweet(tweetId, authed.token);
    return jsonOk({ id: tweetId });
  } catch (e) {
    return errorResponse(e);
  }
}
