import { env } from "@/lib/env";
import { Eyebrow } from "@/components/ui/Primitives";

/** App Store バッジ（SVG 自前。公式素材はビルド時に差し替え可） */
function AppStoreBadge() {
  return (
    <span className="inline-flex items-center gap-2 rounded-[8px] border border-crack bg-rock px-3 py-2 text-chalk">
      <svg width="18" height="22" viewBox="0 0 18 22" aria-hidden="true" fill="currentColor">
        <path d="M14.9 11.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9-.7 0-1.8-.8-3-.8-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.4 1.2 0 1.6-.8 3-.8s1.8.8 3 .7c1.3 0 2-1.1 2.8-2.3.9-1.3 1.2-2.6 1.3-2.6-.1 0-2.5-.9-2.5-3.8zM12.6 4.8c.6-.8 1.1-1.9.9-3-.9 0-2 .6-2.7 1.4-.6.7-1.1 1.8-1 2.9 1.1.1 2.1-.5 2.8-1.3z" />
      </svg>
      <span className="flex flex-col leading-none">
        <span className="text-[9px] text-dust">Download on the</span>
        <span className="font-display text-[15px] font-bold">App Store</span>
      </span>
    </span>
  );
}

/**
 * Web → iOS アプリへの導線。
 * variant="gym" のときは「このジムをアプリで開く」（ユニバーサルリンク未整備のため App Store へ）。
 */
export function AppCta({ variant = "default", gymName, className = "" }: { variant?: "default" | "gym" | "compact"; gymName?: string; className?: string }) {
  const title =
    variant === "gym" ? `${gymName ?? "このジム"}をアプリで開く` : "ボル活はアプリで記録する";
  const body =
    variant === "gym"
      ? "イキタイに登録して、登った日を写真つきで残せます。"
      : "現在地から近いジムを地図で探し、登った記録と統計を自動で。";

  if (variant === "compact") {
    return (
      <a href={env.appStoreUrl} target="_blank" rel="noopener noreferrer" className={`pressable inline-flex ${className}`} aria-label="App Store でイワノボリタイを入手">
        <AppStoreBadge />
      </a>
    );
  }

  return (
    <aside className={`grain relative overflow-hidden rounded-card bg-ledge p-5 md:p-6 ${className}`}>
      <div className="relative flex flex-col gap-4">
        <Eyebrow>iOS APP</Eyebrow>
        <div className="flex flex-col gap-1">
          <h3 className="text-h3">{title}</h3>
          <p className="text-small text-dust">{body}</p>
        </div>
        <a href={env.appStoreUrl} target="_blank" rel="noopener noreferrer" className="pressable inline-flex w-fit" aria-label="App Store でイワノボリタイを入手">
          <AppStoreBadge />
        </a>
      </div>
    </aside>
  );
}
