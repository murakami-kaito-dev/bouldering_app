import { apiRequest, apiRequestOrNull, toNumber } from "./client";
import type { MonthlyStats, PublicProfile, RawMonthlyStats, RawPublicProfile } from "./types";

export function normalizeProfile(r: RawPublicProfile): PublicProfile {
  return {
    id: r.user_id,
    name: r.user_name ?? "",
    iconUrl: r.user_icon_url ?? null,
    introduce: r.user_introduce ?? "",
    boulStartDate: r.boul_start_date ? r.boul_start_date.slice(0, 10) : null,
    homeGymId: r.home_gym_id ?? null,
  };
}

/** 公開プロフィール（認証不要） */
export async function getPublicProfile(userId: string): Promise<PublicProfile | null> {
  const raw = await apiRequestOrNull<RawPublicProfile>(`/users/${encodeURIComponent(userId)}/profile`, { revalidate: 60 });
  return raw ? normalizeProfile(raw) : null;
}

/** 月次統計（months_ago=0 が今月。JST 基準） */
export async function getMonthlyStats(userId: string, monthsAgo = 0): Promise<MonthlyStats | null> {
  const raw = await apiRequestOrNull<RawMonthlyStats>(
    `/users/${encodeURIComponent(userId)}/stats/monthly?months_ago=${monthsAgo}`,
    { revalidate: 60 },
  );
  if (!raw) return null;
  return {
    totalVisits: toNumber(raw.total_visits),
    uniqueGyms: toNumber(raw.unique_gyms),
    weeklyAverage: toNumber(raw.weekly_average),
    topGyms: (raw.top_gyms ?? []).map((g) => ({ gymId: g.gym_id, gymName: g.gym_name, visitCount: toNumber(g.visit_count) })),
  };
}

// ---- 以下は要ログイン（Firebase ID トークン）

/** 本人の行（未登録なら 404 → null） */
export async function getMe(uid: string, token: string): Promise<RawPublicProfile | null> {
  return apiRequestOrNull<RawPublicProfile>(`/users/${encodeURIComponent(uid)}`, { token });
}

/** SNS ログイン直後の本人行の作成（要トークン・本人 uid のみ） */
export async function createMe(uid: string, token: string): Promise<void> {
  await apiRequest<unknown>("/users", { method: "POST", token, body: { user_id: uid } });
}

export async function getFavoriteGymIds(uid: string, token: string): Promise<number[]> {
  const data = await apiRequest<Array<{ gym_id: number } | number>>(`/users/${encodeURIComponent(uid)}/favorite-gyms`, { token });
  return data.map((g) => (typeof g === "number" ? g : g.gym_id));
}

export async function addFavoriteGym(uid: string, gymId: number, token: string): Promise<void> {
  await apiRequest<unknown>(`/users/${encodeURIComponent(uid)}/favorite-gyms`, { method: "POST", token, body: { gym_id: gymId } });
}

export async function removeFavoriteGym(uid: string, gymId: number, token: string): Promise<void> {
  await apiRequest<unknown>(`/users/${encodeURIComponent(uid)}/favorite-gyms/${gymId}`, { method: "DELETE", token });
}
