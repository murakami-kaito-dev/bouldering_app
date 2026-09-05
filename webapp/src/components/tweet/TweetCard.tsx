import Image from "next/image";
import Link from "next/link";
import type { Tweet } from "@/lib/api/types";
import { Tape } from "@/components/ui/Tape";

/** 'YYYY-MM-DD' → '2026.09.01（月）' */
export function formatVisitedDate(ymd: string): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(ymd);
  if (!m) return ymd;
  const d = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
  const w = ["日", "月", "火", "水", "木", "金", "土"][d.getUTCDay()];
  return `${m[1]}.${m[2]}.${m[3]}（${w}）`;
}

export function Avatar({ src, name, size = 40 }: { src: string | null; name: string; size?: number }) {
  if (src) {
    return (
      <Image
        src={src}
        alt={name}
        width={size}
        height={size}
        className="rounded-pill bg-ledge object-cover"
        style={{ width: size, height: size }}
      />
    );
  }
  return (
    <span
      className="inline-flex items-center justify-center rounded-pill bg-ledge font-display font-bold text-dust"
      style={{ width: size, height: size, fontSize: Math.round(size * 0.4) }}
      aria-hidden="true"
    >
      {name.slice(0, 1) || "?"}
    </span>
  );
}

/**
 * ボル活カード（みんなのボル活・ジム詳細のボル活タブ・マイページで共用）。
 * showGym=false のときはジム名の行を省く（ジム詳細タブ用）。
 */
export function TweetCard({ tweet, showGym = true, className = "" }: { tweet: Tweet; showGym?: boolean; className?: string }) {
  const photos = tweet.mediaUrls.slice(0, 4);
  return (
    <article className={`flex flex-col gap-3 rounded-card bg-joint p-4 md:p-5 ${className}`}>
      <header className="flex items-center gap-3">
        <Link href={`/users/${encodeURIComponent(tweet.userId)}`} className="pressable shrink-0 rounded-pill" aria-label={`${tweet.userName} のプロフィール`}>
          <Avatar src={tweet.userIconUrl} name={tweet.userName} />
        </Link>
        <div className="flex min-w-0 flex-col">
          <Link href={`/users/${encodeURIComponent(tweet.userId)}`} className="truncate font-display text-[15px] font-bold text-chalk hover:underline underline-offset-4">
            {tweet.userName || "名もなきクライマー"}
          </Link>
          <span className="font-numeric text-[13px] tracking-[0.04em] text-dust">{formatVisitedDate(tweet.visitedDate)}</span>
        </div>
        {showGym ? (
          <Link
            href={`/gyms/${tweet.gymId}`}
            className="ml-auto flex min-w-0 max-w-[50%] items-center gap-2 text-right text-small text-dust hover:text-chalk"
          >
            <span className="truncate">{tweet.gymName}</span>
            <Tape tone="wall">{tweet.prefecture.replace(/[都府県]$/, "")}</Tape>
          </Link>
        ) : null}
      </header>
      {tweet.content ? <p className="whitespace-pre-wrap break-words text-[15px] leading-[1.75] text-chalk">{tweet.content}</p> : null}
      {photos.length > 0 ? (
        <div className={`grid gap-1 overflow-hidden rounded-card ${photos.length === 1 ? "grid-cols-1" : "grid-cols-2"}`}>
          {photos.map((url, i) => (
            <div key={url + i} className={`relative bg-ledge ${photos.length === 1 ? "aspect-[4/3]" : "aspect-square"}`}>
              <Image src={url} alt={`${tweet.gymName} での写真 ${i + 1}`} fill sizes="(min-width: 768px) 360px, 100vw" className="object-cover" />
            </div>
          ))}
        </div>
      ) : null}
    </article>
  );
}
