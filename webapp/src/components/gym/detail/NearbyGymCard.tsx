import Link from "next/link";
import type { Gym } from "@/lib/api/types";
import { GymTypeTape } from "@/components/ui/Tape";
import { SectionHeader } from "@/components/ui/Primitives";
import { formatYen } from "@/lib/gym/types";

export interface NearbyItem {
  gym: Gym;
  distanceKm: number;
}

function formatKm(km: number): string {
  if (km < 10) return km.toFixed(1);
  return Math.round(km).toLocaleString("ja-JP");
}

/** 「近くのジム」用の小さなカード（検索チームの GymCard には依存しない） */
export function NearbyGymCard({ gym, distanceKm }: NearbyItem) {
  return (
    <Link
      href={`/gyms/${gym.id}`}
      className="pressable flex h-full flex-col gap-3 rounded-card border border-transparent bg-joint p-4 hover:border-crack hover:bg-ledge focus-visible:rounded-card"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex min-w-0 flex-col">
          <span className="truncate font-display text-[16px] font-bold text-chalk">{gym.name}</span>
          <span className="text-small text-dust">{gym.city}</span>
        </div>
        <span className="shrink-0 font-numeric text-[20px] font-semibold leading-none text-dust">
          {formatKm(distanceKm)}
          <span className="ml-0.5 text-[12px] text-ash">km</span>
        </span>
      </div>
      <div className="flex flex-wrap gap-1.5">
        {gym.types.map((t) => (
          <GymTypeTape key={t} type={t} />
        ))}
      </div>
      <div className="mt-auto flex items-baseline gap-4 font-numeric text-[15px] font-semibold tracking-[0.02em]">
        <span className="text-tape-yellow">
          {gym.ikitaiCount.toLocaleString("ja-JP")}
          <span className="ml-1 text-[11px] text-dust">イキタイ</span>
        </span>
        <span className="text-chalk">
          {gym.minimumFee === null ? "—" : `¥${formatYen(gym.minimumFee)}`}
          {gym.minimumFee === null ? null : <span className="ml-0.5 text-[11px] text-dust">〜</span>}
        </span>
      </div>
    </Link>
  );
}

export function NearbyGyms({ prefecture, items, className = "" }: { prefecture: string; items: NearbyItem[]; className?: string }) {
  if (items.length === 0) return null;
  return (
    <section className={`flex flex-col gap-6 ${className}`} aria-labelledby="nearby-gyms-heading">
      <SectionHeader eyebrow={`NEARBY · ${prefecture}`} title={<span id="nearby-gyms-heading">近くのジム</span>} />
      <ul className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
        {items.map((it) => (
          <li key={it.gym.id}>
            <NearbyGymCard {...it} />
          </li>
        ))}
      </ul>
    </section>
  );
}
