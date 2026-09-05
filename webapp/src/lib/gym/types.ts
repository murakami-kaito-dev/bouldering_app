import type { Gym, GymType } from "@/lib/api/types";
import { prefectureOrder } from "./prefectures";

/** 種別の表示名と色（DESIGN.md: 赤=ボルダリング／緑=リード／シアン=スピード） */
export const GYM_TYPE_META: Record<GymType, { label: string; short: string; colorVar: string; tailwindText: string }> = {
  bouldering: { label: "ボルダリング", short: "BOULDER", colorVar: "var(--color-hold-red)", tailwindText: "text-hold-red" },
  lead: { label: "リード", short: "LEAD", colorVar: "var(--color-hold-green)", tailwindText: "text-hold-green" },
  speed: { label: "スピード", short: "SPEED", colorVar: "var(--color-hold-cyan)", tailwindText: "text-hold-cyan" },
};

export const GYM_TYPES: GymType[] = ["bouldering", "lead", "speed"];

/** 人気スコア（アプリと同じ重み: イキタイ 0.7 ＋ ボル活 0.3） */
export function popularity(g: Pick<Gym, "ikitaiCount" | "boulCount">): number {
  return g.ikitaiCount * 0.7 + g.boulCount * 0.3;
}

export function sortByGeography<T extends Pick<Gym, "prefecture" | "name">>(gyms: T[]): T[] {
  return [...gyms].sort((a, b) => {
    const d = prefectureOrder(a.prefecture) - prefectureOrder(b.prefecture);
    return d !== 0 ? d : a.name.localeCompare(b.name, "ja");
  });
}

export function sortByPopularity<T extends Pick<Gym, "ikitaiCount" | "boulCount" | "name">>(gyms: T[]): T[] {
  return [...gyms].sort((a, b) => popularity(b) - popularity(a) || a.name.localeCompare(b.name, "ja"));
}

/** 2 点間の距離（km・Haversine） */
export function distanceKm(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const R = 6371;
  const toRad = (x: number) => (x * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const s = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}

/** 名前・住所での部分一致（ひらがな/カタカナ・全角英数の揺れを吸収） */
export function normalizeQuery(s: string): string {
  return s
    .normalize("NFKC")
    .toLowerCase()
    .replace(/[ァ-ヶ]/g, (ch) => String.fromCharCode(ch.charCodeAt(0) - 0x60)) // カタカナ→ひらがな
    .replace(/\s+/g, "");
}

export function matchesQuery(g: Pick<Gym, "name" | "prefecture" | "city" | "addressLine">, q: string): boolean {
  const n = normalizeQuery(q);
  if (!n) return true;
  return normalizeQuery(`${g.name}${g.prefecture}${g.city}${g.addressLine}`).includes(n);
}

export function formatYen(n: number | null): string {
  if (n === null || !Number.isFinite(n)) return "—";
  return `${n.toLocaleString("ja-JP")}`;
}
