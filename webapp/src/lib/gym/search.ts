import type { Gym, GymType, WeekHours } from "@/lib/api/types";
import { isOpenNow } from "./hours";
import { PREFECTURES, prefectureOrder } from "./prefectures";
import { GYM_TYPES, distanceKm, normalizeQuery } from "./types";

/**
 * 検索ページ（/gyms・/gyms/area/[slug]）で使う軽量なジム型と、絞り込み・並び替え・URL 状態の変換。
 * サーバー（SSR の初期絞り込み）とブラウザ（クライアントでの再絞り込み）の両方から同じ関数を使う。
 *
 * - `GymSummary` は全ジム（約 430 件）をブラウザへ渡すための最小形。料金全文・レンタル・電話・HP は落とす。
 * - 営業中判定は `lib/gym/hours.ts`（JST 固定）。`now` を引数で受け、SSR とハイドレーションで同じ時刻を使えるようにする。
 */

// ---------------------------------------------------------------- GymSummary

export interface GymSummary {
  id: number;
  name: string;
  prefecture: string;
  city: string;
  addressLine: string;
  lat: number;
  lng: number;
  types: GymType[];
  /** 最低料金（円）。不明は null */
  minimumFee: number | null;
  ikitaiCount: number;
  boulCount: number;
  hours: WeekHours;
}

export function toGymSummary(g: Gym): GymSummary {
  return {
    id: g.id,
    name: g.name,
    prefecture: g.prefecture,
    city: g.city,
    addressLine: g.addressLine,
    lat: g.lat,
    lng: g.lng,
    types: g.types,
    minimumFee: g.minimumFee,
    ikitaiCount: g.ikitaiCount,
    boulCount: g.boulCount,
    hours: g.hours,
  };
}

/** BFF（/api/gyms）のレスポンス形 */
export interface GymSummaryResponse {
  total: number;
  gyms: GymSummary[];
}

// ---------------------------------------------------------------- 検索状態

export type SortKey = "popular" | "geo" | "near";
export const SORT_KEYS: SortKey[] = ["popular", "geo", "near"];
export const SORT_LABELS: Record<SortKey, string> = { popular: "人気順", geo: "地域順", near: "近い順" };

export interface SearchState {
  /** ジム名・地名のテキスト */
  q: string;
  /** 都道府県（正式名。例: 東京都） */
  prefs: string[];
  types: GymType[];
  /** 営業中のみ */
  open: boolean;
  sort: SortKey;
}

export const EMPTY_SEARCH: SearchState = { q: "", prefs: [], types: [], open: false, sort: "popular" };

/** ブラウザの現在地（近い順のときだけ使う。URL には入れない） */
export interface GeoPoint {
  lat: number;
  lng: number;
}

type ParamsLike = Record<string, string | string[] | undefined> | URLSearchParams;

function readParam(sp: ParamsLike, key: string): string | undefined {
  if (sp instanceof URLSearchParams) return sp.get(key) ?? undefined;
  const v = sp[key];
  return Array.isArray(v) ? v[0] : v;
}

const isGymType = (v: string): v is GymType => (GYM_TYPES as string[]).includes(v);
const isSortKey = (v: string): v is SortKey => (SORT_KEYS as string[]).includes(v);
const isPrefecture = (v: string): boolean => (PREFECTURES as readonly string[]).includes(v);

/** `?q=&pref=東京都,神奈川県&type=bouldering,lead&open=1&sort=near` → SearchState。不正値は黙って落とす */
export function parseSearchParams(sp: ParamsLike): SearchState {
  const split = (v: string | undefined) =>
    (v ?? "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
  const prefs = Array.from(new Set(split(readParam(sp, "pref")).filter(isPrefecture)));
  const types = Array.from(new Set(split(readParam(sp, "type")).filter(isGymType)));
  const sortRaw = readParam(sp, "sort") ?? "";
  return {
    q: (readParam(sp, "q") ?? "").trim().slice(0, 60),
    prefs,
    types,
    open: readParam(sp, "open") === "1",
    sort: isSortKey(sortRaw) ? sortRaw : "popular",
  };
}

/** SearchState → クエリ文字列（先頭の ? なし。既定値は省く。空なら ""） */
export function serializeSearchState(s: SearchState): string {
  const sp = new URLSearchParams();
  if (s.q) sp.set("q", s.q);
  if (s.prefs.length) sp.set("pref", s.prefs.join(","));
  if (s.types.length) sp.set("type", s.types.join(","));
  if (s.open) sp.set("open", "1");
  if (s.sort !== "popular") sp.set("sort", s.sort);
  return sp.toString();
}

export function hasActiveFilters(s: SearchState): boolean {
  return s.q !== "" || s.prefs.length > 0 || s.types.length > 0 || s.open;
}

// ---------------------------------------------------------------- 絞り込み・並び替え

/**
 * 名前・住所での部分一致。`lib/gym/types.ts` の `matchesQuery` と同じ規則（NFKC・カナ→かな・空白除去）を
 * GymSummary にも使えるようにしたもの。
 */
export function summaryMatchesQuery(g: GymSummary, q: string): boolean {
  const n = normalizeQuery(q);
  if (!n) return true;
  return normalizeQuery(`${g.name}${g.prefecture}${g.city}${g.addressLine}`).includes(n);
}

/** 人気スコア（アプリと同じ重み: イキタイ 0.7 ＋ ボル活 0.3。`lib/gym/types.ts` の popularity と同じ式） */
export function summaryPopularity(g: GymSummary): number {
  return g.ikitaiCount * 0.7 + g.boulCount * 0.3;
}

export function filterGyms(gyms: GymSummary[], s: SearchState, now: Date): GymSummary[] {
  const prefSet = s.prefs.length ? new Set(s.prefs) : null;
  return gyms.filter((g) => {
    if (prefSet && !prefSet.has(g.prefecture)) return false;
    if (s.types.length && !s.types.some((t) => g.types.includes(t))) return false;
    if (s.open && !isOpenNow(g.hours, now)) return false;
    if (s.q && !summaryMatchesQuery(g, s.q)) return false;
    return true;
  });
}

export function sortGyms(gyms: GymSummary[], sort: SortKey, origin: GeoPoint | null): GymSummary[] {
  const byName = (a: GymSummary, b: GymSummary) => a.name.localeCompare(b.name, "ja");
  const list = [...gyms];
  if (sort === "near" && origin) {
    return list.sort(
      (a, b) => distanceKm(origin.lat, origin.lng, a.lat, a.lng) - distanceKm(origin.lat, origin.lng, b.lat, b.lng) || byName(a, b),
    );
  }
  if (sort === "geo") {
    return list.sort((a, b) => {
      const d = prefectureOrder(a.prefecture) - prefectureOrder(b.prefecture);
      if (d !== 0) return d;
      const c = a.city.localeCompare(b.city, "ja");
      return c !== 0 ? c : byName(a, b);
    });
  }
  // popular（near で現在地が無いときも人気順に倒す）
  return list.sort((a, b) => summaryPopularity(b) - summaryPopularity(a) || byName(a, b));
}

/** 絞り込み＋並び替え（SSR の初期表示とブラウザ側で共通） */
export function searchGyms(gyms: GymSummary[], s: SearchState, now: Date, origin: GeoPoint | null = null): GymSummary[] {
  return sortGyms(filterGyms(gyms, s, now), s.sort, origin);
}

// ---------------------------------------------------------------- 表示用

/** 距離の表示（"850 m" / "2.4 km" / "38 km"） */
export function formatDistance(km: number): string {
  if (!Number.isFinite(km)) return "";
  if (km < 1) return `${Math.round(km * 100) * 10} m`;
  if (km < 10) return `${km.toFixed(1)} km`;
  return `${Math.round(km)} km`;
}

/** 種別ごとの件数（都道府県ページの導入文などに使う） */
export function countByType(gyms: GymSummary[]): Record<GymType, number> {
  const c: Record<GymType, number> = { bouldering: 0, lead: 0, speed: 0 };
  for (const g of gyms) for (const t of g.types) c[t] += 1;
  return c;
}

/** 市区町村ごとにまとめる（地域順に並んだ配列を渡す前提。出現順を保つ） */
export function groupByCity(gyms: GymSummary[]): Array<{ city: string; gyms: GymSummary[] }> {
  const groups: Array<{ city: string; gyms: GymSummary[] }> = [];
  for (const g of gyms) {
    const key = g.city || "その他";
    const last = groups[groups.length - 1];
    if (last && last.city === key) last.gyms.push(g);
    else groups.push({ city: key, gyms: [g] });
  }
  return groups;
}
