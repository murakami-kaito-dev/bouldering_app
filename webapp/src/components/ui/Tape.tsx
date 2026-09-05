import type { ReactNode } from "react";
import type { GymType } from "@/lib/api/types";
import { GYM_TYPE_META } from "@/lib/gym/types";

type Tone = "wall" | "red" | "green" | "cyan" | "yellow" | "ash" | "chalk";

const TONE_VAR: Record<Tone, string> = {
  wall: "var(--color-wall)",
  red: "var(--color-hold-red)",
  green: "var(--color-hold-green)",
  cyan: "var(--color-hold-cyan)",
  yellow: "var(--color-tape-yellow)",
  ash: "var(--color-ash)",
  chalk: "var(--color-chalk)",
};

/**
 * 課題テープ（サイトの署名）。種別・状態・タブに使う。
 * - filled=false: 色 12% の地に色文字
 * - filled=true : 色の塗りに墨文字（選択中）
 */
export function Tape({
  tone = "wall",
  filled = false,
  children,
  className = "",
  title,
}: {
  tone?: Tone;
  filled?: boolean;
  children: ReactNode;
  className?: string;
  title?: string;
}) {
  const c = TONE_VAR[tone];
  const style = filled
    ? { background: c, color: tone === "chalk" || tone === "yellow" ? "var(--color-wall-ink)" : "var(--color-wall-ink)" }
    : { background: `color-mix(in srgb, ${c} 14%, transparent)`, color: c };
  return (
    <span className={`tape ${className}`} style={style} title={title}>
      <span>{children}</span>
    </span>
  );
}

const TYPE_TONE: Record<GymType, Tone> = { bouldering: "red", lead: "green", speed: "cyan" };

export function GymTypeTape({ type, filled = false, long = false }: { type: GymType; filled?: boolean; long?: boolean }) {
  const m = GYM_TYPE_META[type];
  return (
    <Tape tone={TYPE_TONE[type]} filled={filled} title={m.label}>
      {long ? m.label : m.short}
    </Tape>
  );
}

export function OpenTape({ open }: { open: boolean }) {
  return (
    <Tape tone={open ? "green" : "ash"} filled={open}>
      {open ? "OPEN" : "CLOSE"}
    </Tape>
  );
}
