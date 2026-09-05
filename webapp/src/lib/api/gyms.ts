import { apiRequest, apiRequestOrNull, toNumber } from "./client";
import type { Gym, GymPhotosResponse, GymType, RawGym, RawTweet, Tweet, WeekHours } from "./types";
import { normalizeTweet } from "./tweets";

/** "10:00:00" → "10:00"。'-'・空・null は null（休み） */
const hhmm = (v: string | null | undefined): string | null => {
  if (!v || v === "-") return null;
  const m = /^(\d{1,2}):(\d{2})/.exec(v);
  return m ? `${m[1].padStart(2, "0")}:${m[2]}` : null;
};

export function normalizeGym(r: RawGym): Gym {
  const types: GymType[] = [];
  if (r.is_bouldering_gym) types.push("bouldering");
  if (r.is_lead_gym) types.push("lead");
  if (r.is_speed_gym) types.push("speed");
  const hours: WeekHours = [
    { open: hhmm(r.sun_open), close: hhmm(r.sun_close) },
    { open: hhmm(r.mon_open), close: hhmm(r.mon_close) },
    { open: hhmm(r.tue_open), close: hhmm(r.tue_close) },
    { open: hhmm(r.wed_open), close: hhmm(r.wed_close) },
    { open: hhmm(r.thu_open), close: hhmm(r.thu_close) },
    { open: hhmm(r.fri_open), close: hhmm(r.fri_close) },
    { open: hhmm(r.sat_open), close: hhmm(r.sat_close) },
  ];
  const name = (r.gym_name ?? "").trim();
  return {
    id: r.gym_id,
    name,
    hpLink: r.hp_link && r.hp_link !== "-" ? r.hp_link : null,
    prefecture: r.prefecture ?? "",
    city: r.city ?? "",
    addressLine: r.address_line ?? "",
    fullAddress: `${r.prefecture ?? ""}${r.city ?? ""}${r.address_line ?? ""}`,
    lat: toNumber(r.latitude),
    lng: toNumber(r.longitude),
    tel: r.tel_no && r.tel_no !== "-" ? r.tel_no : null,
    fee: r.fee ?? "",
    minimumFee: r.minimum_fee ?? null,
    rentalFee: r.equipment_rental_fee ?? "",
    types,
    ikitaiCount: toNumber(r.ikitai_count),
    boulCount: toNumber(r.boul_count),
    hours,
  };
}

/** 全ジム（約 430 件・約 1MB）。サーバー側で 1 時間キャッシュ */
export async function getAllGyms(): Promise<Gym[]> {
  const raw = await apiRequest<RawGym[]>("/gyms", { revalidate: 3600, tags: ["gyms"] });
  return raw.map(normalizeGym);
}

export async function getGym(id: number): Promise<Gym | null> {
  const raw = await apiRequestOrNull<RawGym>(`/gyms/${id}`, { revalidate: 600, tags: ["gyms", `gym:${id}`] });
  return raw ? normalizeGym(raw) : null;
}

/** 写真（自前 or Google Places）。Places の呼び出し節約のため 1 日キャッシュ */
export async function getGymPhotos(id: number): Promise<GymPhotosResponse> {
  const data = await apiRequestOrNull<GymPhotosResponse>(`/gyms/${id}/photos`, { revalidate: 86400, tags: [`gym:${id}`] });
  return data ?? { source: "none", photos: [] };
}

export interface Page<T> {
  items: T[];
  /** 次ページのカーソル（無ければ null） */
  nextCursor: string | null;
}

/** そのジムへのボル活（新しい順・cursor ページング） */
export async function getGymTweets(id: number, limit = 20, cursor?: string | null): Promise<Page<Tweet>> {
  const qs = new URLSearchParams({ limit: String(limit) });
  if (cursor) qs.set("cursor", cursor);
  const raw = await apiRequest<RawTweet[]>(`/gyms/${id}/tweets?${qs}`, { revalidate: 60, tags: [`gym:${id}:tweets`] });
  const items = raw.map(normalizeTweet);
  return { items, nextCursor: items.length === limit ? String(items[items.length - 1].id) : null };
}
