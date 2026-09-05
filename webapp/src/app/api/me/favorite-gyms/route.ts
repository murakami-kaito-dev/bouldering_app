import { apiRequest } from "@/lib/api/client";
import { errorResponse, isResponse, jsonOk, requireAuth } from "@/lib/auth/server";

interface RawFavoriteGym {
  gym_id: number;
  gym_name: string;
  prefecture: string;
  city: string;
}

export interface FavoriteGym {
  id: number;
  name: string;
  prefecture: string;
  city: string;
}

/** GET /api/me/favorite-gyms → GET /users/:uid/favorite-gyms（イキタイ一覧。ジム行が返るので必要な列だけに絞る） */
export async function GET(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  try {
    const rows = await apiRequest<RawFavoriteGym[]>(`/users/${encodeURIComponent(ctx.uid)}/favorite-gyms`, { token: ctx.token });
    const gyms: FavoriteGym[] = rows.map((g) => ({
      id: g.gym_id,
      name: (g.gym_name ?? "").trim(),
      prefecture: g.prefecture ?? "",
      city: g.city ?? "",
    }));
    return jsonOk(gyms);
  } catch (e) {
    return errorResponse(e);
  }
}
