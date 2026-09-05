import type { DayHours, Gym, WeekHours } from "@/lib/api/types";

/**
 * 営業時間の判定。**日本時間（JST）固定**（ジムは日本にある。閲覧者の端末やサーバーの TZ に依らない）。
 * アプリ側 `gym_hours_utils.dart`／バックエンド `jstTime.ts` と同じ規約。
 */
const JST_OFFSET_MS = 9 * 60 * 60 * 1000;

/** JST の「いま」を UTC 値にずらした Date（getUTC* で JST の年月日時分が読める） */
export function nowJst(now: Date = new Date()): Date {
  return new Date(now.getTime() + JST_OFFSET_MS);
}

export const DAY_LABELS_JA = ["日", "月", "火", "水", "木", "金", "土"] as const;

/** 今日（JST）の曜日 0=日 … 6=土 */
export function todayIndexJst(now: Date = new Date()): number {
  return nowJst(now).getUTCDay();
}

/** "HH:MM"（JST のいま） */
export function nowHHMMJst(now: Date = new Date()): string {
  const j = nowJst(now);
  return `${String(j.getUTCHours()).padStart(2, "0")}:${String(j.getUTCMinutes()).padStart(2, "0")}`;
}

export function todayHours(hours: WeekHours, now: Date = new Date()): DayHours {
  return hours[todayIndexJst(now)];
}

/** 営業中か（open <= now <= close。深夜またぎは close < open として扱う） */
export function isOpenNow(hours: WeekHours, now: Date = new Date()): boolean {
  const { open, close } = todayHours(hours, now);
  if (!open || !close) return false;
  const t = nowHHMMJst(now);
  if (close >= open) return t >= open && t <= close;
  // 例: 22:00 - 02:00
  return t >= open || t <= close;
}

export type OpenStatus =
  | { kind: "open"; closesAt: string }
  | { kind: "closed-today" }
  | { kind: "before-open"; opensAt: string }
  | { kind: "after-close"; closedAt: string };

/** 一覧・詳細で「OPEN 〜21:00」「本日休み」「14:00 から」のように出すための状態 */
export function openStatus(hours: WeekHours, now: Date = new Date()): OpenStatus {
  const { open, close } = todayHours(hours, now);
  if (!open || !close) return { kind: "closed-today" };
  if (isOpenNow(hours, now)) return { kind: "open", closesAt: close };
  const t = nowHHMMJst(now);
  if (t < open) return { kind: "before-open", opensAt: open };
  return { kind: "after-close", closedAt: close };
}

export function openStatusLabel(s: OpenStatus): string {
  switch (s.kind) {
    case "open":
      return `営業中 〜${s.closesAt}`;
    case "closed-today":
      return "本日休み";
    case "before-open":
      return `${s.opensAt} 開店`;
    case "after-close":
      return "本日は閉店";
  }
}

/** 週の営業時間を「月〜日」の順で表示用に並べる（今日にフラグ） */
export function weekRows(gym: Gym, now: Date = new Date()) {
  const today = todayIndexJst(now);
  const order = [1, 2, 3, 4, 5, 6, 0];
  return order.map((i) => {
    const d = gym.hours[i];
    return {
      dayIndex: i,
      label: DAY_LABELS_JA[i],
      text: d.open && d.close ? `${d.open} – ${d.close}` : "休み",
      isToday: i === today,
      isClosed: !(d.open && d.close),
    };
  });
}

/** JST の今日 'YYYY-MM-DD' */
export function todayYmdJst(now: Date = new Date()): string {
  return nowJst(now).toISOString().slice(0, 10);
}
