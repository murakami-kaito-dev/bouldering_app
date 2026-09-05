import { getMonthlyStats } from "@/lib/api/users";
import { errorResponse, isResponse, jsonOk, requireAuth } from "@/lib/auth/server";

/** GET /api/me/stats?months_ago=0 → GET /users/:uid/stats/monthly */
export async function GET(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  const raw = new URL(req.url).searchParams.get("months_ago");
  const monthsAgo = Math.min(12, Math.max(0, Number.parseInt(raw ?? "0", 10) || 0));
  try {
    const stats = await getMonthlyStats(ctx.uid, monthsAgo);
    return jsonOk(stats ?? { totalVisits: 0, uniqueGyms: 0, weeklyAverage: 0, topGyms: [] });
  } catch (e) {
    return errorResponse(e);
  }
}
