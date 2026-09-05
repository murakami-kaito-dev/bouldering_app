import Link from "next/link";
import { PREFECTURE_SLUGS, REGIONS } from "@/lib/gym/prefectures";

/**
 * 「都道府県から探す」。7 地方をカードにし、各都道府県のジム数を Barlow（tnum）で並べる。
 * counts は getAllGyms() から呼び出し側で数える（都道府県名 → 件数）。
 */
export function PrefectureGrid({ counts }: { counts: Record<string, number> }) {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {REGIONS.map((region) => {
        const total = region.prefectures.reduce((s, p) => s + (counts[p] ?? 0), 0);
        return (
          <section key={region.name} aria-labelledby={`region-${region.name}`} className="flex flex-col gap-3 rounded-card bg-joint p-5">
            <div className="flex items-baseline justify-between gap-3">
              <h3 id={`region-${region.name}`} className="text-h3">
                {region.name}
              </h3>
              <span className="font-numeric text-[13px] font-semibold tracking-[0.08em] text-ash">
                {total.toLocaleString("ja-JP")} GYMS
              </span>
            </div>
            <ul className="grid grid-cols-2 gap-x-4 gap-y-1">
              {region.prefectures.map((p) => {
                const n = counts[p] ?? 0;
                return (
                  <li key={p}>
                    <Link
                      href={`/gyms/area/${PREFECTURE_SLUGS[p]}`}
                      className="pressable flex items-baseline justify-between gap-2 rounded-tape px-1 py-1 text-[14px] text-chalk hover:bg-ledge"
                    >
                      <span>{p}</span>
                      <span className={`font-numeric text-[15px] font-semibold ${n === 0 ? "text-ash" : "text-dust"}`}>{n.toLocaleString("ja-JP")}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </section>
        );
      })}
    </div>
  );
}
