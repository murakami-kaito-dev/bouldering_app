import Link from "next/link";
import type { Gym } from "@/lib/api/types";
import { GymTypeTape, OpenTape } from "@/components/ui/Tape";
import { Stat } from "@/components/ui/Primitives";
import { formatYen } from "@/lib/gym/types";
import { openStatus, openStatusLabel } from "@/lib/gym/hours";
import { PREFECTURE_SLUGS } from "@/lib/gym/prefectures";

/** パンくず: ジムを探す › 都道府県（都道府県ページが引ける場合のみリンク） */
export function GymBreadcrumb({ prefecture }: { prefecture: string }) {
  const slug = (PREFECTURE_SLUGS as Record<string, string | undefined>)[prefecture];
  return (
    <nav aria-label="パンくず" className="text-eyebrow text-dust">
      <ol className="flex flex-wrap items-center gap-2">
        <li>
          <Link href="/gyms" className="rounded-tape hover:text-chalk">
            ジムを探す
          </Link>
        </li>
        <li aria-hidden="true">›</li>
        <li>
          {slug ? (
            <Link href={`/gyms/area/${slug}`} className="rounded-tape hover:text-chalk">
              {prefecture}
            </Link>
          ) : (
            <span>{prefecture}</span>
          )}
        </li>
      </ol>
    </nav>
  );
}

/** ヒーロー: ジム名・種別テープ・営業状態（JST）・市区町村・課題ボード（イキタイ／ボル活／最低料金） */
export function GymHero({ gym }: { gym: Gym }) {
  const status = openStatus(gym.hours);
  const isOpen = status.kind === "open";
  return (
    <header className="flex flex-col gap-6">
      <div className="flex flex-col gap-3">
        <h1 className="text-h1">{gym.name}</h1>
        <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
          <div className="flex flex-wrap gap-1.5">
            {gym.types.map((t) => (
              <GymTypeTape key={t} type={t} long />
            ))}
          </div>
          <span className="inline-flex items-center gap-2">
            <OpenTape open={isOpen} />
            <span className={`font-numeric text-[14px] font-semibold tracking-[0.04em] ${isOpen ? "text-hold-green" : "text-dust"}`}>
              {openStatusLabel(status)}
            </span>
          </span>
        </div>
        <p className="text-small text-dust">
          {gym.prefecture}
          {gym.city}
        </p>
      </div>

      <div role="group" className="flex flex-wrap items-end gap-x-10 gap-y-4 rounded-card bg-joint px-5 py-5 md:px-6" aria-label="ジムの数字">
        <Stat label="イキタイ" value={gym.ikitaiCount.toLocaleString("ja-JP")} unit="人" tone="yellow" />
        <Stat label="ボル活" value={gym.boulCount.toLocaleString("ja-JP")} unit="件" />
        <Stat
          label="最低料金"
          value={gym.minimumFee === null ? "—" : `¥${formatYen(gym.minimumFee)}`}
          unit={gym.minimumFee === null ? undefined : "〜"}
        />
      </div>
    </header>
  );
}
