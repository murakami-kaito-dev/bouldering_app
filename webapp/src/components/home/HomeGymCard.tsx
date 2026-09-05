import Link from "next/link";
import type { ReactNode } from "react";
import type { Gym } from "@/lib/api/types";
import { GymTypeTape, OpenTape } from "@/components/ui/Tape";
import { formatYen } from "@/lib/gym/types";
import { openStatusLabel, type OpenStatus } from "@/lib/gym/hours";

function StatSm({ label, value, unit, tone = "chalk" }: { label: string; value: ReactNode; unit?: string; tone?: "chalk" | "yellow" }) {
  return (
    <div className="flex flex-col gap-1">
      <dt className="text-eyebrow text-ash">{label}</dt>
      <dd className={`text-stat flex items-baseline gap-[0.3em] text-[22px] ${tone === "yellow" ? "text-tape-yellow" : "text-chalk"}`}>
        <span>{value}</span>
        {unit ? <span className="text-[11px] font-semibold tracking-[0.04em] text-dust">{unit}</span> : null}
      </dd>
    </div>
  );
}

/**
 * ホーム用のコンパクトなジムカード（写真なし）。
 * 面は joint、ホバーで ledge＋crack 線。営業状態は呼び出し側が JST で判定して渡す。
 */
export function HomeGymCard({ gym, status }: { gym: Gym; status: OpenStatus }) {
  const open = status.kind === "open";
  return (
    <Link
      href={`/gyms/${gym.id}`}
      className="pressable flex h-full flex-col gap-3 rounded-card border border-transparent bg-joint p-4 hover:border-crack hover:bg-ledge focus-visible:rounded-card"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h3 className="text-h3 truncate">{gym.name}</h3>
          <p className="truncate text-small text-dust">
            {gym.prefecture} {gym.city}
          </p>
        </div>
        <OpenTape open={open} />
      </div>

      <div className="flex flex-wrap gap-1.5">
        {gym.types.map((t) => (
          <GymTypeTape key={t} type={t} />
        ))}
      </div>

      <div className="mt-auto flex items-end justify-between gap-4 border-t border-crack pt-3">
        <dl className="flex items-end gap-5">
          <StatSm label="イキタイ" value={gym.ikitaiCount.toLocaleString("ja-JP")} tone="yellow" />
          <StatSm label="ボル活" value={gym.boulCount.toLocaleString("ja-JP")} />
          {gym.minimumFee !== null ? <StatSm label="料金" value={formatYen(gym.minimumFee)} unit="円〜" /> : null}
        </dl>
        <span className="shrink-0 font-numeric text-[13px] tracking-[0.04em] text-dust">{openStatusLabel(status)}</span>
      </div>
    </Link>
  );
}
