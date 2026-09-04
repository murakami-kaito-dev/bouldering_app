/**
 * 時刻の基準（JST 固定）の共通部品
 *
 * 方針（2026-09-05 決定）:
 * - このサービスは日本のジム・日本のユーザー向けなので、「今日」「今月」の判断は
 *   端末やサーバーのタイムゾーンに関係なく **日本時間（JST, UTC+9・夏時間なし）** で行う
 * - DB とサーバーの保存は UTC のまま（TIMESTAMPTZ）。DATE 列（訪問日・生年月日・開始日）は
 *   「日付だけ」の値として扱い、時刻を付けない
 * - 日付の受け渡しは 'YYYY-MM-DD' 文字列に統一する（JS の Date に変換すると UTC 深夜の
 *   時刻付きになり、日本時間では 09:00 として解釈されて日付ずれの原因になる）
 */

export const JST_OFFSET_MS = 9 * 60 * 60 * 1000;

/** 日付だけの値（年・月(1-12)・日） */
export interface YmdDate {
  year: number;
  month: number;
  day: number;
}

/** 'YYYY-MM-DD' 形式に整形する */
export function formatYmd(d: YmdDate): string {
  const mm = String(d.month).padStart(2, '0');
  const dd = String(d.day).padStart(2, '0');
  return `${d.year}-${mm}-${dd}`;
}

/**
 * ある瞬間（既定: 現在）を日本時間の日付に直す
 * 実装: UTC の瞬間に 9 時間を足し、その UTC 年月日を読む（夏時間が無いので固定オフセットで正しい）
 */
export function toJstDate(instant: Date = new Date()): YmdDate {
  const shifted = new Date(instant.getTime() + JST_OFFSET_MS);
  return { year: shifted.getUTCFullYear(), month: shifted.getUTCMonth() + 1, day: shifted.getUTCDate() };
}

/** 日本時間の今日（'YYYY-MM-DD'） */
export function jstToday(now: Date = new Date()): string {
  return formatYmd(toJstDate(now));
}

/** 'YYYY-MM-DD…' 形式の文字列から日付部分だけを取り出す（時刻付き ISO が来ても先頭の日付を使う） */
export function ymdFromString(value: string): string | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(value);
  return m ? `${m[1]}-${m[2]}-${m[3]}` : null;
}

/** その日付（'YYYY-MM-DD'）が日本時間の今日より未来か */
export function isAfterJstToday(dateValue: string, now: Date = new Date()): boolean {
  const ymd = ymdFromString(dateValue);
  if (!ymd) return false; // 形式が違うものは別の検査（isISO8601）に任せる
  return ymd > jstToday(now); // 'YYYY-MM-DD' は文字列比較で日付順になる
}

/** 月の日数 */
export function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/**
 * 日本時間で見た「N か月前の月」の範囲
 * - start: その月の 1 日 / end: 翌月の 1 日（半開区間 [start, end) で DATE 列と比較する）
 * - daysInMonth: その月の日数
 * - elapsedDays: 今月なら今日の日付（経過日数）、過去の月なら日数（統計の週平均の分母に使う）
 */
export function jstMonthRange(monthsAgo: number, now: Date = new Date()): {
  start: string;
  end: string;
  daysInMonth: number;
  elapsedDays: number;
  isCurrentMonth: boolean;
} {
  const today = toJstDate(now);
  // 月をさかのぼる（年またぎは Date.UTC が正規化してくれる）
  const target = new Date(Date.UTC(today.year, today.month - 1 - monthsAgo, 1));
  const year = target.getUTCFullYear();
  const month = target.getUTCMonth() + 1;
  const next = new Date(Date.UTC(year, month, 1));
  const days = daysInMonth(year, month);
  const isCurrentMonth = monthsAgo === 0;
  return {
    start: formatYmd({ year, month, day: 1 }),
    end: formatYmd({ year: next.getUTCFullYear(), month: next.getUTCMonth() + 1, day: 1 }),
    daysInMonth: days,
    elapsedDays: isCurrentMonth ? today.day : days,
    isCurrentMonth,
  };
}
