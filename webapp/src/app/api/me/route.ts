import { createMe, getMe } from "@/lib/api/users";
import { errorResponse, isResponse, jsonError, jsonOk, requireAuth } from "@/lib/auth/server";

/** GET /api/me → GET /users/:uid（本人行。未登録なら 404） */
export async function GET(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  try {
    const me = await getMe(ctx.uid, ctx.token);
    if (!me) return jsonError(404, "未登録のユーザーです", "USER_NOT_FOUND");
    return jsonOk(me);
  } catch (e) {
    return errorResponse(e);
  }
}

/** POST /api/me → POST /users { user_id: uid }（SNS ログイン直後の初回登録） */
export async function POST(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  try {
    await createMe(ctx.uid, ctx.token);
    return jsonOk({ user_id: ctx.uid }, 201);
  } catch (e) {
    return errorResponse(e);
  }
}
