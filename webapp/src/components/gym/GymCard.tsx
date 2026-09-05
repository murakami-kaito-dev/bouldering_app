"use client";

import Link from "next/link";
import type { GymSummary } from "@/lib/gym/search";
import { formatDistance } from "@/lib/gym/search";
import { formatYen } from "@/lib/gym/types";
import { GymTypeTape, OpenTape } from "@/components/ui/Tape";

/**
 * 一覧の 1 行（DESIGN.md「GymCard」）。
 * - joint 面・角丸 14・padding 16。hover で ledge ＋ crack の枠。
 * - 左 96×96 は写真プレースホルダ（一覧用の写真 API が無いので岩肌の面に種別テープ）。
 * - 地図と連動: selected で左端に 3px の wall 縦線、highlighted（マーカー hover）で枠を出す。
 * - `open` が null のときは営業状態を出さない（静的ページの mount 前）。
 */
export function GymCard({
  gym,
  open,
  selected = false,
  highlighted = false,
  distanceKm = null,
  onHover,
  compact = false,
  className = "",
}: {
  gym: GymSummary;
  open: boolean | null;
  selected?: boolean;
  highlighted?: boolean;
  distanceKm?: number | null;
  onHover?: (id: number | null) => void;
  /** 地図オーバーレイのカルーセル用（幅固定・下段を 1 行に） */
  compact?: boolean;
  className?: string;
}) {
  const primary = gym.types[0];
  const surface = selected || highlighted ? "border-crack bg-ledge" : "border-transparent bg-joint";
  return (
    <article
      data-gym-id={gym.id}
      className={`relative rounded-card border transition-colors duration-150 hover:border-crack hover:bg-ledge ${surface} ${className}`}
      onMouseEnter={onHover ? () => onHover(gym.id) : undefined}
      onMouseLeave={onHover ? () => onHover(null) : undefined}
      aria-current={selected ? "true" : undefined}
    >
      {selected ? <span className="absolute left-0 top-4 bottom-4 w-[3px] rounded-tape bg-wall" aria-hidden="true" /> : null}
      <Link
        href={`/gyms/${gym.id}`}
        className={`flex gap-4 rounded-card ${compact ? "p-3" : "p-4"}`}
        aria-label={`${gym.name}（${gym.prefecture}${gym.city}）の詳細`}
      >
        {/* 写真プレースホルダ（岩肌 + 種別テープ） */}
        <div
          className={`grain relative flex shrink-0 items-end justify-start overflow-hidden rounded-card bg-rock ${compact ? "h-[72px] w-[72px]" : "h-24 w-24"}`}
          role="img"
          aria-label={`${gym.name} の写真（準備中）`}
        >
          <span className="absolute left-2 bottom-2">{primary ? <GymTypeTape type={primary} /> : null}</span>
        </div>

        <div className="flex min-w-0 flex-1 flex-col gap-1.5">
          <div className="flex min-w-0 flex-col">
            <h3 className="truncate font-display text-[18px] font-bold leading-[1.3] text-chalk">{gym.name}</h3>
            <p className="truncate text-[13px] leading-[1.5] text-dust">
              {gym.prefecture}
              {gym.city}
              {distanceKm !== null ? (
                <span className="ml-2 font-numeric text-[13px] font-semibold tracking-[0.04em] text-chalk">{formatDistance(distanceKm)}</span>
              ) : null}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-1.5">
            {gym.types.map((t) => (
              <GymTypeTape key={t} type={t} />
            ))}
            {open !== null ? <OpenTape open={open} /> : null}
          </div>

          <dl className={`mt-auto flex items-end gap-4 pt-1 ${compact ? "gap-3" : ""}`}>
            <MiniStat label="イキタイ" value={gym.ikitaiCount} tone="yellow" />
            <MiniStat label="ボル活" value={gym.boulCount} />
            <MiniStat label="最低料金" value={gym.minimumFee === null ? "—" : `¥${formatYen(gym.minimumFee)}〜`} />
          </dl>
        </div>
      </Link>
    </article>
  );
}

/** カード内の小さな Stat（Primitives.Stat の sm より詰めた一覧用） */
function MiniStat({ label, value, tone = "chalk" }: { label: string; value: number | string; tone?: "chalk" | "yellow" }) {
  return (
    <div className="flex flex-col gap-0.5">
      <dt className="text-eyebrow text-[11px] text-dust">{label}</dt>
      <dd className={`font-numeric text-[20px] font-bold leading-none tracking-[0]${tone === "yellow" ? "text-tape-yellow" : "text-chalk"}`}>
        {value}
      </dd>
    </div>
  );
}
