import { nowJst } from "@/lib/gym/hours";

/**
 * ボルダリング歴（'YYYY-MM-DD' の開始日 → 「3年2ヶ月」）。JST の今日基準。
 * 開始日が未来・不正なら null。
 */
export function climbingHistory(boulStartDate: string | null | undefined, now: Date = new Date()): { years: number; months: number } | null {
  if (!boulStartDate) return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(boulStartDate);
  if (!m) return null;
  const sy = Number(m[1]);
  const sm = Number(m[2]);
  const sd = Number(m[3]);
  const j = nowJst(now);
  const ty = j.getUTCFullYear();
  const tm = j.getUTCMonth() + 1;
  const td = j.getUTCDate();
  let months = (ty - sy) * 12 + (tm - sm);
  if (td < sd) months -= 1;
  if (months < 0) return null;
  return { years: Math.floor(months / 12), months: months % 12 };
}

export function climbingHistoryLabel(h: { years: number; months: number } | null): string {
  if (!h) return "—";
  if (h.years === 0 && h.months === 0) return "はじめたばかり";
  if (h.years === 0) return `${h.months}ヶ月`;
  if (h.months === 0) return `${h.years}年`;
  return `${h.years}年${h.months}ヶ月`;
}

/** 同一オリジン内のパスだけ許可（オープンリダイレクト防止） */
export function safeNextPath(next: string | null | undefined, fallback = "/me"): string {
  if (!next) return fallback;
  if (!next.startsWith("/") || next.startsWith("//") || next.startsWith("/\\")) return fallback;
  return next;
}
